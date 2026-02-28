# Family Health API (FastAPI + MongoDB)

## Structure

```
back/
  app/
    main.py           # FastAPI app, CORS, routers
    config.py         # Settings (pydantic-settings)
    database.py       # MongoDB connection (motor)
    models/           # Pydantic models
      user.py
      person.py
      family.py
    routers/
      auth.py         # POST /auth/register, /auth/login, GET /auth/me
      families.py     # GET/PATCH /families/me
      persons.py      # CRUD /persons
    utils/
      security.py     # JWT, password hashing
      dependencies.py # get_current_user_id, get_current_user_family_id
  requirements.txt
  .env.example
```

## Setup

1. Create a virtualenv and install dependencies:

   ```bash
   python -m venv venv
   venv\Scripts\activate   # Windows
   pip install -r requirements.txt
   ```

2. Copy `.env.example` to `.env` and set `MONGODB_URL` (and optionally `JWT_SECRET_KEY`).

3. Run MongoDB locally or use a cloud instance (e.g. MongoDB Atlas).

4. Start the API:

   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

## API

- **POST /api/auth/register** — Body: `{ "email", "password", "family_code"?: string }`. Creates user; if `family_code` is provided, joins that family, else creates a new family. Returns `{ "access_token", "token_type", "user" }`.
- **POST /api/auth/login** — Body: `{ "email", "password" }`. Returns `{ "access_token", "token_type", "user" }`.
- **GET /api/auth/me** — Requires `Authorization: Bearer <token>`. Returns current user.

- **GET /api/families/me** — Returns family with `father`, `mother`, `children` (camelCase).
- **PATCH /api/families/me** — Body: `{ "family_history"?: string[] }`.

- **GET /api/persons** — List all members of current user's family.
- **POST /api/persons** — Body: Person fields + `family_id`, `role` ("father" | "mother" | "child").
- **GET /api/persons/{id}** — Get one person.
- **PATCH /api/persons/{id}** — Update person (partial).
- **DELETE /api/persons/{id}** — Delete person.

All person/family responses use camelCase for Flutter compatibility.
