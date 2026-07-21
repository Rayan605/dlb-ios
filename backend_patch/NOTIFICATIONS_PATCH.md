# Patch backend — Notifications

L'app mobile récupère les annonces via `GET /notifications` et affiche une
notification système à chaque nouvelle. Depuis la page admin web, tu crées une
annonce via `POST /admin/notifications` — elle apparaît alors chez tous les
utilisateurs.

Trois petites modifs à appliquer sur ton backend existant.

---

## 1. `app/database.py` — créer la table

Dans `init_db()`, ajoute ce bloc **avant** `_migrate(cur)` (à côté des autres
`CREATE TABLE`) :

```python
        # NOTIFICATIONS — annonces poussées depuis l'admin
        cur.execute("""
        CREATE TABLE IF NOT EXISTS notifications (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            title      TEXT NOT NULL,
            body       TEXT NOT NULL,
            event_id   INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE SET NULL
        )
        """)
        cur.execute("CREATE INDEX IF NOT EXISTS idx_notif_created ON notifications(id DESC)")
```

---

## 2. `app/schemas.py` — schémas

Ajoute à la fin du fichier :

```python
# -------- NOTIFICATIONS --------
class NotificationOut(BaseModel):
    id:         int
    title:      str
    body:       str
    event_id:   Optional[int] = None
    created_at: Optional[str] = None


class NotificationCreate(BaseModel):
    title:    str = Field(min_length=1, max_length=120)
    body:     str = Field(min_length=1, max_length=500)
    event_id: Optional[int] = None
```

---

## 3. `app/main.py` — endpoints

Ajoute ces routes (n'importe où après la création de `app`) :

```python
# ─── NOTIFICATIONS ────────────────────────────────────────
@app.get("/notifications", response_model=List[schemas.NotificationOut])
def list_notifications(limit: int = 50):
    """Feed public des dernières annonces (consommé par l'app mobile)."""
    with get_db() as conn:
        return conn.execute(
            "SELECT id, title, body, event_id, created_at "
            "FROM notifications ORDER BY id DESC LIMIT ?",
            (max(1, min(limit, 100)),),
        ).fetchall()


@app.post("/admin/notifications", response_model=schemas.NotificationOut, status_code=201)
def create_notification(payload: schemas.NotificationCreate,
                        admin: dict = Depends(require_admin)):
    """Crée une annonce depuis l'admin. Visible immédiatement par tous."""
    with get_db() as conn:
        if payload.event_id is not None:
            ev = conn.execute("SELECT id FROM events WHERE id=?",
                              (payload.event_id,)).fetchone()
            if not ev:
                raise HTTPException(404, "Soirée introuvable.")
        cur = conn.execute(
            "INSERT INTO notifications (title, body, event_id) VALUES (?,?,?)",
            (payload.title.strip(), payload.body.strip(), payload.event_id),
        )
        return conn.execute(
            "SELECT id, title, body, event_id, created_at FROM notifications WHERE id=?",
            (cur.lastrowid,),
        ).fetchone()


@app.delete("/admin/notifications/{notif_id}", status_code=204)
def delete_notification(notif_id: int, admin: dict = Depends(require_admin)):
    with get_db() as conn:
        conn.execute("DELETE FROM notifications WHERE id=?", (notif_id,))
    return None
```

---

## (Option) Créer une notif automatiquement à chaque nouvelle soirée

Si tu veux qu'une annonce parte **automatiquement** dès que tu crées une soirée,
ajoute cette ligne à la fin de la fonction `create_event(...)` dans `main.py`,
juste avant le `return` :

```python
        conn.execute(
            "INSERT INTO notifications (title, body, event_id) VALUES (?,?,?)",
            (f"Nouvelle soirée : {title}",
             f"{title} — {city} ({department}). Les réservations sont ouvertes !",
             eid),
        )
```

Tu peux garder **les deux** : auto à la création + envoi manuel quand tu veux
depuis l'admin.

---

## Notes importantes

- **CORS** : l'app mobile n'a pas d'origine web, donc les requêtes passent sans
  souci. Rien à changer. Si tu veux verrouiller `CORS_ORIGINS`, laisse `*` ou
  ajoute simplement l'origine de ton front web.
- Aucune migration destructive : la table est créée si absente, l'app tourne
  même si tu appliques le patch plus tard (le feed renverra juste une liste vide
  en attendant).
