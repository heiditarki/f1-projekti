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
- Frontend on http://127.0.0.1:3001

## Manual Setup

### Backend (FastF1 + FastAPI)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --host 127.0.0.1 --port 8000 --reload
```

To deploy on Heroku:

```bash
cd backend
heroku create f1-backend-tarkiainen
heroku config:set ALLOWED_ORIGINS="https://your-vercel-app.vercel.app"
git push heroku main
```

### Frontend (Elm)

```bash
cd frontend
npm install
npm start
```

The development server will rebuild automatically on save and serve the app at
http://127.0.0.1:3001.

## API Endpoints

- `GET /next-race` – Latest event, countdown, and session schedule details
- `GET /races/{year}` – Overview list of races for the selected season
- `GET /race/{year}/{round}` – Detailed race metadata and results summary
- `GET /race/{year}/{round}/drivers` – Classified driver order with finishing
  stats
- `GET /race/{year}/{round}/positions` – Lap-by-lap position changes for each
  driver
- `GET /race/{year}/{round}/highlights` – Curated highlights, key moments, and
  context

## Deployment & Security

- Set `ALLOWED_ORIGINS` (comma-separated) before starting the backend to
  restrict CORS, for example:
  ```bash
  export ALLOWED_ORIGINS="http://127.0.0.1:3001,https://f1-backend.tarkiainen"
  ```
- When deploying to Vercel the provided `vercel.json` adds security headers
  (HSTS, X-Frame-Options, etc.). Adjust the file if you need additional policies
  such as a Content Security Policy.
- Keep backend credentials and API tokens out of the frontend bundle—store them
  as environment variables in Vercel or your hosting provider.
- The build script reads `API_BASE_URL` (defaults to `http://127.0.0.1:8000`).
  On Vercel set it to your deployed backend URL (e.g.
  `https://f1-backend.tarkiainen`) so `Config.elm` is generated with the correct
  endpoint.

## Development

- Backend uses FastF1 with caching in `backend/f1_cache/`
- Frontend hot-reloads automatically when you save Elm files
- Use `./dev.sh` for the most stable development experience
