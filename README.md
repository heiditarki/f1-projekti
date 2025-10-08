## Backend Setup (FastF1 + FastAPI)

1. **Navigate to backend folder:**

```bash
cd backend
```

2. **Create and activate virtual environment** macOS/Linux

```
python3 -m venv venv
source venv/bin/activate
```

3. **Install dependencies**

```
pip install -r requirements.txt
```

4. **Run the backend**

```
uvicorn app:app --reload
```

Notes:

- f1_cache/ stores FastF1 session data to speed up repeated requests.
- Keep the venv activated whenever running the backend.

## Frontend Setup (Elm)

1. **Navigate to frontend folder**

```
cd ../frontend
```

2. **Install dependencies:**

```
npm install
```

3. **Compile and serve Elm with live reload**

```
npm start
```
