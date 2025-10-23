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
        # Get event info from schedule
        schedule = fastf1.get_event_schedule(year)
        event = schedule[schedule["RoundNumber"] == round].iloc[0]

        # Load the race session
        session = fastf1.get_session(year, round, "R")
        session.load()

        # Get weather data
        weather = None
        if not session.weather_data.empty:
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

        # Calculate total laps
        total_laps = (
            int(session.laps["LapNumber"].max()) if not session.laps.empty else 0
        )

        # Get race duration (winner's total time)
        race_time = None
        if not session.results.empty:
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
                if hasattr(event, "Session5DateUtc")
                else None
            ),
            "totalLaps": total_laps,
            "raceDuration": race_time,
            "weather": weather,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
