import logging
import os
import time
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError

from collections import OrderedDict
from numbers import Number
from threading import Lock
from typing import Any, Optional, cast

import fastf1
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
from fastf1.req import RateLimitExceededError

# Enable cache
cache_dir = "f1_cache"
os.makedirs(cache_dir, exist_ok=True)
fastf1.Cache.enable_cache(cache_dir)

logger = logging.getLogger(__name__)

app = FastAPI()

# CORS
default_allowed_origins = os.getenv(
    "ALLOWED_ORIGINS",
    ",".join(
        [
            "https://f1-projekti.vercel.app",
            "http://127.0.0.1:5173",
            "http://localhost:5173",
            "http://0.0.0.0:5173",
            "http://127.0.0.1:3001",
            "http://localhost:3001",
            "http://0.0.0.0:3001",
        ]
    ),
)
allowed_origins = [
    origin.strip() for origin in default_allowed_origins.split(",") if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["Accept", "Content-Type"],
    max_age=600,
)


SESSION_CACHE_SIZE = int(os.getenv("SESSION_CACHE_SIZE", "6"))
_session_cache_lock = Lock()
_session_cache: "OrderedDict[tuple[int, int], Any]" = OrderedDict()
_session_load_locks: dict[tuple[int, int], Lock] = {}

# Schedule cache to avoid hitting rate limits
SCHEDULE_CACHE_TTL = int(os.getenv("SCHEDULE_CACHE_TTL", "3600"))  # 1 hour default
_schedule_cache_lock = Lock()
_schedule_cache: dict[int, tuple[Any, float]] = {}  # year -> (schedule, timestamp)

# Timeout for FastF1 operations (30 seconds)
FASTF1_TIMEOUT = int(os.getenv("FASTF1_TIMEOUT", "30"))

# Thread pool for timeout handling
_executor = ThreadPoolExecutor(max_workers=4)


def run_with_timeout(func, timeout_seconds: int, *args, **kwargs):
    """Run a function with a timeout."""
    future = _executor.submit(func, *args, **kwargs)
    try:
        return future.result(timeout=timeout_seconds)
    except FutureTimeoutError:
        logger.warning(f"Operation timed out after {timeout_seconds} seconds")
        raise TimeoutError(f"Operation timed out after {timeout_seconds} seconds")


def cleanup_stale_locks():
    """Remove locks that are no longer in use."""
    with _session_cache_lock:
        keys_to_remove = []
        for key, lock in _session_load_locks.items():
            if not lock.locked():
                keys_to_remove.append(key)
        for key in keys_to_remove:
            _session_load_locks.pop(key, None)


def _normalize_cache_key(year: int, round_num: int) -> tuple[int, int]:
    return (int(year), int(round_num))


def get_cached_schedule(year: int) -> Optional[Any]:
    """Get schedule from cache if still valid, otherwise None."""
    with _schedule_cache_lock:
        if year in _schedule_cache:
            schedule, timestamp = _schedule_cache[year]
            if time.time() - timestamp < SCHEDULE_CACHE_TTL:
                return schedule
            # Expired, remove it
            _schedule_cache.pop(year, None)
    return None


def store_schedule_in_cache(year: int, schedule: Any) -> None:
    """Store schedule in cache with current timestamp."""
    with _schedule_cache_lock:
        _schedule_cache[year] = (schedule, time.time())


def _store_session_in_cache(key: tuple[int, int], session: Any) -> Any:
    with _session_cache_lock:
        if key in _session_cache:
            _session_cache.move_to_end(key)
            return _session_cache[key]

        _session_cache[key] = session
        _session_cache.move_to_end(key)

        while len(_session_cache) > SESSION_CACHE_SIZE:
            _session_cache.popitem(last=False)

        return session


def get_cached_session(year: int, round_num: int) -> Any:
    key = _normalize_cache_key(year, round_num)

    with _session_cache_lock:
        cached = _session_cache.get(key)
        if cached is not None:
            _session_cache.move_to_end(key)
            return cached
        load_lock = _session_load_locks.get(key)
        if load_lock is None:
            load_lock = Lock()
            _session_load_locks[key] = load_lock

    try:
        with load_lock:
            with _session_cache_lock:
                cached = _session_cache.get(key)
                if cached is not None:
                    _session_cache.move_to_end(key)
                    return cached

            # Load session with timeout
            def load_session():
                session = fastf1.get_session(year, round_num, "R")
                session.load(
                    laps=True,
                    telemetry=False,
                    weather=True,
                    messages=False,
                )
                return session
            
            try:
                session = run_with_timeout(load_session, FASTF1_TIMEOUT)
            except TimeoutError:
                logger.error(f"Timeout loading session {year}-{round_num}")
                raise HTTPException(
                    status_code=504,
                    detail=f"Timeout loading race session {year}-{round_num}. Please try again.",
                )
            
            # Cleanup stale locks periodically
            if len(_session_load_locks) > 20:
                cleanup_stale_locks()

            with _session_cache_lock:
                existing = _session_cache.get(key)
                if existing is not None:
                    _session_cache.move_to_end(key)
                    return existing

            return _store_session_in_cache(key, session)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Error loading race session {year}-{round_num}: {exc}",
        ) from exc
    finally:
        with _session_cache_lock:
            current_lock = _session_load_locks.get(key)
            if current_lock is load_lock and not current_lock.locked():
                _session_load_locks.pop(key, None)


def event_get(event: Any, key: str, default: Any = None) -> Any:
    if event is None:
        return default

    if hasattr(event, key):
        value = getattr(event, key)
        if value is not None:
            return value

    if isinstance(event, dict):
        return event.get(key, default)

    if isinstance(event, pd.Series) and key in event.index:
        return event.get(key, default)

    return default


def format_timedelta(td):
    """Format timedelta as HH:MM:SS.mmm"""
    if pd.isna(td) or td is None:
        return None

    total_seconds = td.total_seconds()
    hours = int(total_seconds // 3600)
    minutes = int((total_seconds % 3600) // 60)
    seconds = total_seconds % 60

    return f"{hours:02d}:{minutes:02d}:{seconds:06.3f}"


def get_countdown_components(event_time_utc: pd.Timestamp):
    now = pd.Timestamp.now(tz="UTC")

    if pd.isna(event_time_utc):
        return None

    # Ensure event_time_utc is timezone-aware in UTC
    if event_time_utc.tzinfo is None:
        event_time_utc = event_time_utc.tz_localize("UTC")
    else:
        event_time_utc = event_time_utc.tz_convert("UTC")

    delta = event_time_utc - now

    if delta.total_seconds() < 0:
        return {
            "status": "started",
            "totalSeconds": 0,
            "days": 0,
            "hours": 0,
            "minutes": 0,
            "seconds": 0,
        }

    components = delta.components

    # pandas components may have microseconds; account for rounding
    seconds = int(round(components.seconds + components.microseconds / 1_000_000))
    minutes, seconds = divmod(seconds, 60)
    hours = (components.hours + components.days * 24) + minutes // 60
    minutes = minutes % 60
    days, hours = divmod(hours, 24)

    return {
        "status": "upcoming",
        "totalSeconds": int(delta.total_seconds()),
        "days": int(days),
        "hours": int(hours),
        "minutes": int(minutes),
        "seconds": int(seconds),
    }


def normalize_datetime(value):
    if value is None or pd.isna(value):
        return None

    if isinstance(value, pd.Timestamp):
        timestamp = value
    else:
        timestamp = pd.to_datetime(value, utc=True, errors="coerce")

    if pd.isna(timestamp):
        return None

    if timestamp.tzinfo is None:
        timestamp = timestamp.tz_localize("UTC")
    else:
        timestamp = timestamp.tz_convert("UTC")

    return timestamp


def session_iso(event_row, key):
    ts = normalize_datetime(event_row.get(key))
    return ts.isoformat() if ts is not None else None


def safe_str(value):
    if value is None or pd.isna(value):
        return None
    return str(value)


def to_optional_int(value: Any) -> Optional[int]:
    if value is None or pd.isna(value):
        return None

    if isinstance(value, Number):
        return int(value)

    if isinstance(value, str):
        stripped = value.strip()
        if not stripped:
            return None
        try:
            return int(stripped)
        except ValueError:
            numeric_value = pd.to_numeric(stripped, errors="coerce")
            if numeric_value is None or pd.isna(numeric_value):
                return None
            return int(numeric_value)

    return None


@app.get("/health")
def health_check():
    """Health check endpoint that's always fast - used by Fly.io health checks."""
    return {"status": "ok", "timestamp": time.time()}


def extract_event_details(event_row, fallback_year):
    round_number = to_optional_int(
        event_row.get("RoundNumber") if event_row is not None else None
    )

    race_time = normalize_datetime(event_row.get("Session5DateUtc"))

    return {
        "year": int(event_row.get("Year", fallback_year)),
        "round": round_number,
        "raceName": safe_str(
            event_row.get("EventName") or event_row.get("OfficialEventName")
        ),
        "officialName": safe_str(
            event_row.get("OfficialEventName") or event_row.get("EventName")
        ),
        "circuit": safe_str(event_row.get("Location")),
        "country": safe_str(event_row.get("Country")),
        "dateUtc": race_time.isoformat() if race_time is not None else None,
        "sessions": {
            "fp1": session_iso(event_row, "Session1DateUtc"),
            "fp2": session_iso(event_row, "Session2DateUtc"),
            "fp3": session_iso(event_row, "Session3DateUtc"),
            "qualifying": session_iso(event_row, "Session4DateUtc"),
            "race": race_time.isoformat() if race_time is not None else None,
        },
        "countdown": (
            get_countdown_components(race_time) if race_time is not None else None
        ),
    }


@app.get("/next-race")
def get_next_race():
    """Return the next scheduled race with countdown information."""

    now = pd.Timestamp.now(tz="UTC")
    start_year = now.year

    # Check current year and next year as a fallback (if schedule already finished)
    schedule_loaded = False
    upstream_errors: list[str] = []

    for year in range(start_year, start_year + 2):
        # Try cache first
        schedule = get_cached_schedule(year)
        if schedule is not None:
            schedule_loaded = True
        else:
            # Not in cache, fetch from FastF1
            try:
                def fetch_schedule():
                    return fastf1.get_event_schedule(year)
                
                try:
                    schedule = run_with_timeout(fetch_schedule, FASTF1_TIMEOUT)
                except TimeoutError:
                    logger.warning(f"Timeout fetching schedule for {year}")
                    # Try cache one more time in case it was updated
                    schedule = get_cached_schedule(year)
                    if schedule is None:
                        upstream_errors.append(f"{year}: Timeout fetching schedule")
                        continue
                    else:
                        schedule_loaded = True
                        logger.info(f"Using cached schedule for {year} after timeout")
                else:
                    schedule_loaded = True
                    # Store in cache for future requests
                    store_schedule_in_cache(year, schedule)
            except RateLimitExceededError as exc:
                # Rate limited - try cache one more time (might have been updated)
                schedule = get_cached_schedule(year)
                if schedule is not None:
                    schedule_loaded = True
                    logger.warning(
                        "Rate limited, using cached schedule for %s", year
                    )
                else:
                    upstream_errors.append(f"{year}: Rate limit exceeded")
                    logger.warning(
                        "Rate limit exceeded for %s and no cached data available", year
                    )
                    continue
            except ValueError as exc:
                upstream_errors.append(f"{year}: {exc}")
                logger.warning(
                    "Upstream schedule unavailable for %s: %s", year, exc, exc_info=exc
                )
                continue
            except Exception as exc:
                upstream_errors.append(f"{year}: {exc}")
                logger.warning(
                    "Unexpected error loading schedule for %s", year, exc_info=exc
                )
                continue

        if schedule is None:
            continue

        schedule_df = cast(pd.DataFrame, schedule)

        if schedule_df.empty:
            continue

        # Ensure we work with a copy to avoid SettingWithCopy warnings
        upcoming: pd.DataFrame = schedule_df.copy()

        # Filter valid rounds (ignore testing etc.)
        if "RoundNumber" in upcoming.columns:
            round_numbers = cast(
                pd.Series, pd.to_numeric(upcoming["RoundNumber"], errors="coerce")
            )
            valid_round_mask = cast(pd.Series, round_numbers.ge(1)).fillna(False)
            upcoming = upcoming[valid_round_mask]

        if "Session5DateUtc" not in upcoming.columns:
            continue

        # Normalize race date while keeping timezone-aware dtype
        normalized_dates = upcoming["Session5DateUtc"].apply(normalize_datetime)
        normalized_dates = pd.DatetimeIndex(normalized_dates).tz_convert("UTC")
        upcoming = upcoming.drop(columns=["Session5DateUtc"]).assign(
            Session5DateUtc=normalized_dates
        )

        # Keep events with valid race datetime
        upcoming = upcoming[upcoming["Session5DateUtc"].notna()]

        if upcoming.empty:
            continue

        # Separate upcoming and past events
        upcoming_events = cast(
            pd.DataFrame, upcoming[upcoming["Session5DateUtc"] >= now]
        )

        if not upcoming_events.empty:
            next_event = upcoming_events.sort_values("Session5DateUtc").iloc[0]
            details = extract_event_details(next_event, year)
            if details["countdown"] is not None:
                return details

        # If no future events, but we might be during race (small negative delta)
        just_started = cast(
            pd.DataFrame,
            upcoming[upcoming["Session5DateUtc"] >= now - pd.Timedelta(hours=3)],
        )
        if not just_started.empty:
            current_event = just_started.sort_values("Session5DateUtc").iloc[0]
            details = extract_event_details(current_event, year)
            return details

    if not schedule_loaded and upstream_errors:
        raise HTTPException(
            status_code=503,
            detail="Temporarily unable to load schedule from F1 data providers.",
        )

    raise HTTPException(status_code=404, detail="No upcoming races found")


@app.get("/races/{year}")
def get_races(year: int):
    """Get all races for a specific year"""
    # Try cache first
    schedule = get_cached_schedule(year)
    if schedule is None:
        try:
            def fetch_schedule():
                return fastf1.get_event_schedule(year)
            
            try:
                schedule = run_with_timeout(fetch_schedule, FASTF1_TIMEOUT)
            except TimeoutError:
                # Try cache one more time
                schedule = get_cached_schedule(year)
                if schedule is None:
                    raise HTTPException(
                        status_code=504,
                        detail="Timeout fetching schedule and no cached data available. Please try again later.",
                    )
            else:
                # Store in cache for future requests
                store_schedule_in_cache(year, schedule)
        except RateLimitExceededError:
            # Rate limited - try cache one more time
            schedule = get_cached_schedule(year)
            if schedule is None:
                raise HTTPException(
                    status_code=503,
                    detail="Rate limit exceeded and no cached data available. Please try again later.",
                )
    
    try:
        races = []

        for _, row in schedule.iterrows():
            race_date = getattr(row, "Session5DateUtc", None)
            if race_date is None:
                continue

            round_number = int(getattr(row, "RoundNumber", 0))

            # Skip round 0 (pre-season testing, etc.)
            if round_number < 1:
                continue

            races.append(
                {
                    "round": round_number,
                    "race": getattr(
                        row, "EventName", getattr(row, "OfficialEventName", "Unknown")
                    ),
                    "date": str(race_date.date()),
                }
            )

        return {"year": year, "races": races}

    except Exception as e:
        return {"error": str(e)}


@app.get("/race/{year}/{round_num}")
def get_race_overview(year: int, round_num: int):
    """Get basic race overview - name, circuit, date, weather"""
    try:
        # Validate round number
        if round_num < 1:
            raise HTTPException(status_code=400, detail="Round must be 1 or greater")

        # Load the race session once and reuse for all detailed endpoints
        session = get_cached_session(year, round_num)
        event = getattr(session, "event", None)

        if event is None:
            # Try cache first
            schedule = get_cached_schedule(year)
            if schedule is None:
                try:
                    def fetch_schedule():
                        return fastf1.get_event_schedule(year)
                    schedule = run_with_timeout(fetch_schedule, FASTF1_TIMEOUT)
                    store_schedule_in_cache(year, schedule)
                except (TimeoutError, RateLimitExceededError):
                    # Fallback: try to get from cache or raise error
                    schedule = get_cached_schedule(year)
                    if schedule is None:
                        raise HTTPException(
                            status_code=503,
                            detail="Unable to load schedule data. Please try again later.",
                        )
            
            matching_event = schedule[schedule["RoundNumber"] == round_num]
            if matching_event.empty:
                raise HTTPException(status_code=404, detail="Race not found")
            event = matching_event.iloc[0]

        # Get weather data - check if it exists first
        weather = None
        if (
            hasattr(session, "weather_data")
            and session.weather_data is not None
            and not session.weather_data.empty
        ):
            latest_weather = session.weather_data.iloc[-1]
            weather = {
                "airTemp": (
                    float(latest_weather["AirTemp"])
                    if pd.notna(latest_weather["AirTemp"])
                    else None
                ),
                "trackTemp": (
                    float(latest_weather["TrackTemp"])
                    if pd.notna(latest_weather["TrackTemp"])
                    else None
                ),
                "humidity": (
                    float(latest_weather["Humidity"])
                    if pd.notna(latest_weather["Humidity"])
                    else None
                ),
            }

        # Calculate total laps - check if laps data exists
        total_laps = 0
        if (
            hasattr(session, "laps")
            and session.laps is not None
            and not session.laps.empty
        ):
            max_lap = session.laps["LapNumber"].max()
            if pd.notna(max_lap):
                total_laps = int(max_lap)

        # Get race duration (winner's total time)
        race_time = None
        if (
            hasattr(session, "results")
            and session.results is not None
            and not session.results.empty
        ):
            winner = session.results.iloc[0]
            if pd.notna(winner["Time"]):
                race_time = str(winner["Time"])

        # Calculate additional race statistics
        circuit_length = None
        if (
            hasattr(session, "laps")
            and session.laps is not None
            and not session.laps.empty
        ):
            # Estimate circuit length from fastest lap time
            fastest_lap = session.laps[session.laps["LapTime"].notna()]["LapTime"].min()
            if pd.notna(fastest_lap):
                fastest_time_seconds = fastest_lap.total_seconds()
                # Estimate circuit length based on average F1 speed (~200 km/h)
                circuit_length = round((fastest_time_seconds / 3600) * 200, 2)

        # Get number of corners from circuit info
        num_corners = None
        try:
            circuit_info = session.get_circuit_info()
            if hasattr(circuit_info, "corners") and circuit_info.corners is not None:
                num_corners = len(circuit_info.corners)
        except:
            pass

        # Calculate race distance
        race_distance = None
        if circuit_length and total_laps:
            race_distance = round(circuit_length * total_laps, 2)

        event_date = normalize_datetime(event_get(event, "Session5DateUtc"))

        return {
            "round": round_num,
            "raceName": safe_str(event_get(event, "EventName")),
            "circuitName": safe_str(event_get(event, "Location")),
            "country": safe_str(event_get(event, "Country")),
            "date": event_date.date().isoformat() if event_date is not None else None,
            "totalLaps": total_laps,
            "raceDuration": race_time,
            "circuitLength": circuit_length,
            "numCorners": num_corners,
            "raceDistance": race_distance,
            "weather": weather,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/race/{year}/{round}/drivers")
def get_driver_order(year: int, round: int):
    """Get driver finishing order for a race"""
    try:
        # Validate round number
        if round < 1:
            raise HTTPException(status_code=400, detail="Round must be 1 or greater")

        # Load the race session using shared cache
        session = get_cached_session(year, round)

        # Access results after loading - this should now work
        try:
            results = session.results
        except AttributeError as e:
            raise HTTPException(
                status_code=500,
                detail=f"Results not available after loading session. Error: {str(e)}",
            )

        # Check if results exist and are not empty
        if results is None or results.empty:
            raise HTTPException(
                status_code=404, detail="No results found for this race"
            )

        # Get winner's time for calculating gaps
        winner_time = None
        if not results.empty and pd.notna(results.iloc[0]["Time"]):
            winner_time = results.iloc[0]["Time"]

        # Build driver list
        drivers = []
        for _, driver in results.iterrows():
            # Handle position
            position = int(driver["Position"]) if pd.notna(driver["Position"]) else None

            # Get driver info
            driver_info = {
                "position": position,
                "number": (
                    int(driver["DriverNumber"])
                    if pd.notna(driver["DriverNumber"])
                    else None
                ),
                "code": (
                    str(driver["Abbreviation"])
                    if pd.notna(driver["Abbreviation"])
                    else None
                ),
                "firstName": (
                    str(driver["FirstName"]) if pd.notna(driver["FirstName"]) else None
                ),
                "lastName": (
                    str(driver["LastName"]) if pd.notna(driver["LastName"]) else None
                ),
                "team": (
                    str(driver["TeamName"]) if pd.notna(driver["TeamName"]) else None
                ),
                "teamColor": (
                    str(driver["TeamColor"]) if pd.notna(driver["TeamColor"]) else None
                ),
                "gridPosition": (
                    int(driver["GridPosition"])
                    if pd.notna(driver["GridPosition"])
                    else None
                ),
                "status": str(driver["Status"]) if pd.notna(driver["Status"]) else None,
                "points": float(driver["Points"]) if pd.notna(driver["Points"]) else 0,
            }

            # Return time as-is: FastF1 already provides winner's elapsed time and others' gaps
            if pd.notna(driver["Time"]):
                driver_time = driver["Time"]

                if position == 1:
                    # Winner: return elapsed time in HH:MM:SS.mmm format
                    total_seconds = driver_time.total_seconds()
                    hours = int(total_seconds // 3600)
                    minutes = int((total_seconds % 3600) // 60)
                    seconds = total_seconds % 60
                    driver_info["time"] = f"{hours:02d}:{minutes:02d}:{seconds:06.3f}"
                else:
                    # Others: FastF1 Time field is already the gap to winner
                    gap_seconds = driver_time.total_seconds()
                    driver_info["time"] = f"+{gap_seconds:.3f}"
            else:
                driver_info["time"] = None

            drivers.append(driver_info)

        # Sort by position
        drivers.sort(
            key=lambda x: x["position"] if x["position"] is not None else float("inf")
        )

        return {
            "year": year,
            "round": round,
            "raceName": safe_str(
                event_get(getattr(session, "event", None), "EventName")
            ),
            "drivers": drivers,
        }

    except HTTPException:
        raise
    except Exception as e:
        # Log the full error for debugging
        import traceback

        print("Error in get_driver_order:")
        traceback.print_exc()
        raise HTTPException(
            status_code=500, detail=f"Error loading race data: {str(e)}"
        )


@app.get("/race/{year}/{round}/positions")
def get_position_changes(year: int, round: int):
    """Get lap-by-lap position changes for all drivers"""
    try:
        if round < 1:
            raise HTTPException(status_code=400, detail="Round must be 1 or greater")

        session = get_cached_session(year, round)

        if not hasattr(session, "laps") or session.laps is None or session.laps.empty:
            raise HTTPException(status_code=404, detail="No lap data found")

        laps = session.laps

        # Get team colors from results if available
        team_colors = {}
        if (
            hasattr(session, "results")
            and session.results is not None
            and not session.results.empty
        ):
            for (
                _,
                driver,
            ) in session.results.iterrows():
                if pd.notna(driver.get("DriverNumber")) and pd.notna(
                    driver.get("TeamColor")
                ):
                    team_colors[int(driver["DriverNumber"])] = str(driver["TeamColor"])

        # Get unique drivers
        drivers_data = []

        for driver_number in laps["DriverNumber"].unique():
            driver_laps = laps[laps["DriverNumber"] == driver_number].sort_values(
                "LapNumber"
            )

            if driver_laps.empty:
                continue

            # Get driver info from first lap
            first_lap = driver_laps.iloc[0]

            # Build positions array - one position per lap
            positions = []
            pit_laps = []
            dnf_lap = None

            for _, lap in driver_laps.iterrows():
                lap_num = int(lap["LapNumber"]) if pd.notna(lap["LapNumber"]) else None
                position = int(lap["Position"]) if pd.notna(lap["Position"]) else None

                if lap_num and position:
                    # Ensure we have entries for all laps (fill gaps if needed)
                    while len(positions) < lap_num - 1:
                        positions.append(None)
                    positions.append(position)

                    # Check for pit stop (PitOutTime exists)
                    if pd.notna(lap.get("PitOutTime")):
                        pit_laps.append(lap_num)

            driver_num = (
                int(first_lap["DriverNumber"])
                if pd.notna(first_lap["DriverNumber"])
                else None
            )

            driver_info = {
                "driverNumber": driver_num,
                "code": (
                    str(first_lap["Driver"]) if pd.notna(first_lap["Driver"]) else None
                ),
                "team": str(first_lap["Team"]) if pd.notna(first_lap["Team"]) else None,
                "teamColor": team_colors.get(driver_num),
                "positions": positions,
                "pitLaps": pit_laps,
                "dnfLap": dnf_lap,
            }

            drivers_data.append(driver_info)

        # Get total laps from the driver who completed the most laps
        total_laps = (
            max([len(d["positions"]) for d in drivers_data]) if drivers_data else 0
        )

        return {
            "year": year,
            "round": round,
            "raceName": safe_str(
                event_get(getattr(session, "event", None), "EventName")
            ),
            "totalLaps": total_laps,
            "drivers": drivers_data,
        }

    except HTTPException:
        raise
    except Exception as e:
        import traceback

        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/race/{year}/{round}/highlights")
def get_race_highlights(year: int, round: int):
    """Get race highlights - winner, fastest lap, fastest pit stop"""
    try:
        # Validate round number
        if round < 1:
            raise HTTPException(status_code=400, detail="Round must be 1 or greater")

        # Load the race session using shared cache
        session = get_cached_session(year, round)

        # Get results for winner
        results = session.results
        if results is None or results.empty:
            raise HTTPException(
                status_code=404, detail="No results found for this race"
            )

        winner = results.iloc[0]

        # Get fastest lap from laps data
        laps = session.laps
        fastest_lap_info = None
        if laps is not None and not laps.empty:
            # Filter out invalid lap times and find fastest
            valid_laps = laps[
                (laps["LapTime"].notna())
                & (laps["LapTime"] != pd.NaT)
                & (laps["Deleted"] != True)
            ]

            if not valid_laps.empty:
                # Find fastest lap using sort instead of idxmin
                fastest_lap = valid_laps.sort_values("LapTime").iloc[0]
                # Get driver info from results
                driver_number = fastest_lap["DriverNumber"]
                driver_info = results[results["DriverNumber"] == driver_number]

                if not driver_info.empty:
                    driver = driver_info.iloc[0]
                    fastest_lap_info = {
                        "driverCode": (
                            str(fastest_lap["Driver"])
                            if pd.notna(fastest_lap["Driver"])
                            else None
                        ),
                        "driverName": (
                            f"{driver['FirstName']} {driver['LastName']}"
                            if pd.notna(driver["FirstName"])
                            and pd.notna(driver["LastName"])
                            else str(fastest_lap["Driver"])
                        ),
                        "lapNumber": (
                            int(fastest_lap["LapNumber"])
                            if pd.notna(fastest_lap["LapNumber"])
                            else None
                        ),
                        "lapTime": (
                            format_timedelta(fastest_lap["LapTime"])
                            if pd.notna(fastest_lap["LapTime"])
                            else None
                        ),
                        "team": (
                            str(fastest_lap["Team"])
                            if pd.notna(fastest_lap["Team"])
                            else None
                        ),
                        "teamColor": (
                            str(driver["TeamColor"])
                            if pd.notna(driver["TeamColor"])
                            else None
                        ),
                    }

        # Get fastest pit stop from laps data
        fastest_pit_info = None
        if laps is not None and not laps.empty:
            # Find laps with complete pit stop data (both PitInTime and PitOutTime exist)
            pit_laps = laps[
                (laps["PitInTime"].notna())
                & (laps["PitOutTime"].notna())
                & (laps["PitInTime"] != pd.NaT)
                & (laps["PitOutTime"] != pd.NaT)
            ]

            if not pit_laps.empty:
                # Calculate pit stop duration (PitInTime - PitOutTime)
                pit_laps = pit_laps.copy()
                pit_laps["PitDuration"] = pit_laps["PitInTime"] - pit_laps["PitOutTime"]

                # Find fastest pit stop using sort instead of idxmin
                fastest_pit = pit_laps.sort_values("PitDuration").iloc[0]
                # Get driver info from results
                driver_number = fastest_pit["DriverNumber"]
                driver_info = results[results["DriverNumber"] == driver_number]

                if not driver_info.empty:
                    driver = driver_info.iloc[0]
                    fastest_pit_info = {
                        "driverCode": (
                            str(fastest_pit["Driver"])
                            if pd.notna(fastest_pit["Driver"])
                            else None
                        ),
                        "driverName": (
                            f"{driver['FirstName']} {driver['LastName']}"
                            if pd.notna(driver["FirstName"])
                            and pd.notna(driver["LastName"])
                            else str(fastest_pit["Driver"])
                        ),
                        "lapNumber": (
                            int(fastest_pit["LapNumber"])
                            if pd.notna(fastest_pit["LapNumber"])
                            else None
                        ),
                        "pitDuration": (
                            format_timedelta(fastest_pit["PitDuration"])
                            if pd.notna(fastest_pit["PitDuration"])
                            else None
                        ),
                        "team": (
                            str(fastest_pit["Team"])
                            if pd.notna(fastest_pit["Team"])
                            else None
                        ),
                        "teamColor": (
                            str(driver["TeamColor"])
                            if pd.notna(driver["TeamColor"])
                            else None
                        ),
                    }

        # Get fastest speed from laps data
        fastest_speed_info = None
        if laps is not None and not laps.empty:
            # Find laps with valid speed data (SpeedFL - Speed at Finish Line)
            speed_laps = laps[(laps["SpeedFL"].notna()) & (laps["SpeedFL"] != pd.NaT)]

            if not speed_laps.empty:
                # Find fastest speed
                fastest_speed = speed_laps.loc[speed_laps["SpeedFL"].idxmax()]
                # Get driver info from results
                driver_number = fastest_speed["DriverNumber"]
                driver_info = results[results["DriverNumber"] == driver_number]

                if not driver_info.empty:
                    driver = driver_info.iloc[0]
                    fastest_speed_info = {
                        "driverCode": (
                            str(fastest_speed["Driver"])
                            if pd.notna(fastest_speed["Driver"])
                            else None
                        ),
                        "driverName": (
                            f"{driver['FirstName']} {driver['LastName']}"
                            if pd.notna(driver["FirstName"])
                            and pd.notna(driver["LastName"])
                            else str(fastest_speed["Driver"])
                        ),
                        "lapNumber": (
                            int(fastest_speed["LapNumber"])
                            if pd.notna(fastest_speed["LapNumber"])
                            else None
                        ),
                        "speed": (
                            float(fastest_speed["SpeedFL"])
                            if pd.notna(fastest_speed["SpeedFL"])
                            else None
                        ),
                        "team": (
                            str(fastest_speed["Team"])
                            if pd.notna(fastest_speed["Team"])
                            else None
                        ),
                        "teamColor": (
                            str(driver["TeamColor"])
                            if pd.notna(driver["TeamColor"])
                            else None
                        ),
                    }

        return {
            "year": year,
            "round": round,
            "raceName": safe_str(
                event_get(getattr(session, "event", None), "EventName")
            ),
            "winner": {
                "driverCode": (
                    str(winner["Abbreviation"])
                    if pd.notna(winner["Abbreviation"])
                    else None
                ),
                "driverName": (
                    f"{winner['FirstName']} {winner['LastName']}"
                    if pd.notna(winner["FirstName"]) and pd.notna(winner["LastName"])
                    else None
                ),
                "raceTime": (
                    format_timedelta(winner["Time"])
                    if pd.notna(winner["Time"])
                    else None
                ),
                "team": (
                    str(winner["TeamName"]) if pd.notna(winner["TeamName"]) else None
                ),
                "teamColor": (
                    str(winner["TeamColor"]) if pd.notna(winner["TeamColor"]) else None
                ),
                "points": float(winner["Points"]) if pd.notna(winner["Points"]) else 0,
            },
            "fastestLap": fastest_lap_info,
            "fastestPitStop": fastest_pit_info,
            "fastestSpeed": fastest_speed_info,
        }

    except HTTPException:
        raise
    except Exception as e:
        import traceback

        traceback.print_exc()
        raise HTTPException(
            status_code=500, detail=f"Error loading race highlights: {str(e)}"
        )
