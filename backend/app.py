import fastf1
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Enable FastF1 cache
fastf1.Cache.enable_cache("f1_cache")

app = FastAPI()

# Allow CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace "*" with your frontend URL in production
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/lapdata/{year}/{race}/{driver}")
def get_lap_data(year: int, race: str, driver: str):
    """
    Returns the fastest lap data for a given driver in a session.
    Example session: 'Q' = Qualifying, 'R' = Race, 'FP1' = Free Practice 1
    """
    try:
        session = fastf1.get_session(year, race, "Q")  # Qualifying session
        session.load()
        laps = session.laps.pick_driver(driver)
        fastest_lap = laps.pick_fastest()

        return {
            "driver": driver,
            "lap_time": str(fastest_lap["LapTime"]),
            "sector1": str(fastest_lap["Sector1Time"]),
            "sector2": str(fastest_lap["Sector2Time"]),
            "sector3": str(fastest_lap["Sector3Time"]),
        }
    except Exception as e:
        return {"error": str(e)}
