# F1 Project

A Formula 1 data visualization application with Elm frontend and FastAPI
backend.

## Quick Start

**Recommended:** Use the development script to start both servers:

```bash
./dev.sh
```

This will start:

- Backend API on http://127.0.0.1:8000
- Frontend on http://localhost:3000

## Manual Setup

### Backend (FastF1 + FastAPI)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --host 127.0.0.1 --port 8000 --reload
```

### Frontend (Elm)

```bash
cd frontend
npm install
npm start
```

## API Endpoints

- `GET /races/{year}` - Get all races for a year
- `GET /race/{year}/{round}` - Get race overview
- `GET /race/{year}/{round}/drivers` - Get driver finishing order
- `GET /race/{year}/{round}/positions` - Get lap-by-lap position changes

## Development

- Backend uses FastF1 with caching in `backend/f1_cache/`
- Frontend hot-reloads automatically when you save Elm files
- Use `./dev.sh` for the most stable development experience
