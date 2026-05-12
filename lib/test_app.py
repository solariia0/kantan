import pytest
from fastapi.testclient import TestClient
from types import SimpleNamespace
from contextlib import contextmanager
from app import app

client = TestClient(app)

class FakeRow:
    def __init__(self, mapping):
        self._mapping = mapping

class FakeResult:
    def __init__(self, rows):
        self._rows = rows

    def all(self):
        return self._rows

    def fetchall(self):
        return self._rows

    # allow iteration if needed
    def __iter__(self):
        return iter(self._rows)

class FakeConnection:
    def __init__(self, result=None):
        self._result = result or FakeResult([])

    def execute(self, sql, params=None):
        return self._result

    def commit(self):
        pass

    def close(self):
        pass

@contextmanager
def fake_connect(result=None):
    yield FakeConnection(result)

def patch_engine_connect(monkeypatch, result=None):
    import myapp
    monkeypatch.setattr(myapp.engine, "connect", lambda: fake_connect(result))

# Tests
def test_read_root():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json() == {"msg": "Kantan is running"}

def test_get_user(monkeypatch):
    rows = [FakeRow({"id": 1, "username": "alice", 'mode': 'jlpt', 'level': 5})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/1")
    assert r.status_code == 200
    assert r.json() == [{"id": 1, "name": "alice"}]

def test_get_kanji_jlpt(monkeypatch):
    rows = [FakeRow({"literal": "日"}), FakeRow({"literal": "月"})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/jlpt/2/1")
    assert r.status_code == 200
    assert r.json() == [{"literal": "日"}, {"literal": "月"}]

def test_get_kanji_id(monkeypatch):
    rows = [FakeRow({"id": 5, "meanings": "sun"})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/kanji_id", params=[("kanji", "日"), ("kanji", "月")])
    assert r.status_code == 200
    assert r.json() == [{"id": 5, "meanings": "sun"}]

def test_kanji_info(monkeypatch):
    rows = [FakeRow({"id": 123, "literal": "日", "onreadings": "ニチ", 'kunreadings': 'ニチ', 'meanings': 'day'})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/kanji/info/日")
    assert r.status_code == 200
    assert r.json() == [({"id": 123, "literal": "日", "onreadings": "ニチ", 'kunreadings': 'ニチ', 'meanings': 'day'})]

def test_post_user_kanji_add(monkeypatch):
    patch_engine_connect(monkeypatch, FakeResult([]))
    payload = {"id": [1, 2, 3]}
    r = client.post("/user_kanji/42", json=payload)
    assert r.status_code in (200, 201, 204)

def test_post_mode(monkeypatch):
    patch_engine_connect(monkeypatch, FakeResult([]))
    payload = {"user_id": 10, "mode": 'jlpt'}
    r = client.post("/10/mode/jlpt", json=payload)
    assert r.status_code in (200, 201, 204)

#update
def test_post_user_kanji_onyomi(monkeypatch):
    patch_engine_connect(monkeypatch, FakeResult([]))
    payload = {"kanji_id": 10, "correct": 1, "wrong": 0}
    r = client.post("/user_kanji/3/onyomi", json=payload)
    assert r.status_code in (200, 201, 204)

def test_post_user_kanji_kunyomi(monkeypatch):
    patch_engine_connect(monkeypatch, FakeResult([]))
    payload = {"kanji_id": 11, "correct": 0, "wrong": 1}
    r = client.post("/user_kanji/3/kunyomi", json=payload)
    assert r.status_code in (200, 201, 204)

def test_total_stats(monkeypatch):
    rows = [FakeRow({"learned kanji": 5, "on_accuracy": 80, "level count": 20})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/total/1")
    assert r.status_code == 200
    assert r.json() == [{"learned kanji": 5, "on_accuracy": 80, "level count": 20}]

def test_user_kanji_total(monkeypatch):
    rows = [FakeRow({"count": 42})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/user_kanji/1/total")
    assert r.status_code == 200
    assert r.json() == [{"count": 42}]

def test_streak_get(monkeypatch):
    rows = [FakeRow({"practiced_at": "2026-05-05", "practiced": True})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/streak/1")
    assert r.status_code == 200
    assert r.json() == [{"practiced_at": "2026-05-05", "practiced": True}]

def test_quiz_jlpt_new(monkeypatch):
    rows = [FakeRow({"id": 1, "literal": "日"})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/quiz/jlpt/new/1")
    assert r.status_code == 200
    assert r.json() == [{"id": 1, "literal": "日"}]

def test_quiz_grade_new(monkeypatch):
    rows = [FakeRow({"id": 2, "literal": "月"})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/quiz/grade/new/1")
    assert r.status_code == 200
    assert r.json() == [{"id": 2, "literal": "月"}]

def test_quiz_grade_known(monkeypatch):
    rows = [FakeRow({"id": 3, "literal": "火"})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/quiz/grade/known/1")
    assert r.status_code == 200
    assert r.json() == [{"id": 3, "literal": "火"}]

def test_quiz_jlpt_kunyomi(monkeypatch):
    rows = [FakeRow({"id": 4, "literal": "水"})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/quiz/jlpt/kunyomi/1")
    assert r.status_code == 200
    assert r.json() == [{"id": 4, "literal": "水"}]

def test_quiz_vocab(monkeypatch):
    rows = [FakeRow({"vocab": "語"})]
    patch_engine_connect(monkeypatch, FakeResult(rows))
    r = client.get("/quiz/vocab/1")
    assert r.status_code == 200
    assert r.json() == [{"vocab": "語"}]
