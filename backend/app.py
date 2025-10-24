import os
import fastf1
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd

# Enable cache
cache_dir = "f1_cache"
os.makedirs(cache_dir, exist_ok=True)
fastf1.Cache.enable_cache(cache_dir)

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/races/{year}")
def get_races(year: int):
    """Get all races for a specific year"""
    try:
        schedule = fastf1.get_event_schedule(year)
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


@app.get("/race/{year}/{round}")
def get_race_overview(year: int, round: int):
    """Get basic race overview - name, circuit, date, weather"""
    try:
        # Validate round number
        if round < 1:
            raise HTTPException(status_code=400, detail="Round must be 1 or greater")

        # Get event info from schedule
        schedule = fastf1.get_event_schedule(year)
        event = schedule[schedule["RoundNumber"] == round].iloc[0]

        # Load the race session
        session = fastf1.get_session(year, round, "R")

        # IMPORTANT: Must call load() before accessing any session data
        session.load()

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
            total_laps = int(session.laps["LapNumber"].max())

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

        return {
            "round": round,
            "raceName": str(event["EventName"]),
            "circuitName": str(event["Location"]),
            "country": str(event["Country"]),
            "date": (
                str(event["Session5DateUtc"].date())
                if pd.notna(event.get("Session5DateUtc"))
                else "NaT"
            ),
            "totalLaps": total_laps,
            "raceDuration": race_time,
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

        # Load the race session
        session = fastf1.get_session(year, round, "R")

        # Load session data with laps - this ensures all data including results are loaded
        # The laps parameter ensures complete data loading
        session.load(laps=True, telemetry=False, weather=False, messages=False)

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
            "raceName": str(session.event["EventName"]),
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

        session = fastf1.get_session(year, round, "R")
        session.load()

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
            "raceName": str(session.event["EventName"]),
            "totalLaps": total_laps,
            "drivers": drivers_data,
        }

    except HTTPException:
        raise
    except Exception as e:
        import traceback

        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
