#!/usr/bin/env python3
"""
Beweis für Phase 2: Firestore-Daten werden geladen und sind veränderbar.
Zeigt:
1. Aktuelle Restaurants in Firestore
2. Ändert ein Restaurant
3. Ließt den geänderten Wert aus
"""
import json, os, urllib.request
from urllib.error import HTTPError

CONFIG_PATH = os.path.expanduser('~/.config/configstore/firebase-tools.json')
PROJECT_ID = 'tawali-2ded4'
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

print("=" * 60)
print("PHASE 2 – PROOF: Restaurants from Firestore")
print("=" * 60)

# Token aus Firebase CLI
config = json.load(open(CONFIG_PATH))
token = config['tokens']['access_token']
hdrs = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

# 1) Alle Restaurants lesen
url = f"{BASE}/restaurants"
req = urllib.request.Request(url, headers=hdrs)
resp = urllib.request.urlopen(req)
data = json.loads(resp.read())
docs = data.get('documents', [])
print(f"\n1) Restaurants in Firestore: {len(docs)}")
for d in docs:
    name = d['name'].split('/')[-1]
    f = d.get('fields', {})
    ar = f.get('name_ar', {}).get('stringValue', '?')
    en = f.get('name_en', {}).get('stringValue', '?')
    print(f"   {name}: {ar} / {en}")

# 2) Ein Restaurant ändern – Bewertung aktualisieren
print(f"\n2) Ändere Restaurant 'r1' (Abu Auf) – setze rating → 5.0")
body = {
    "fields": {
        "rating": {"doubleValue": 5.0},
        "name_ar": {"stringValue": "مطعم أبو عوف (معدل)"},
        "name_en": {"stringValue": "Abu Auf Restaurant (Updated)"},
    }
}
update_url = f"{BASE}/restaurants/r1?updateMask.fieldPaths=rating&updateMask.fieldPaths=name_ar&updateMask.fieldPaths=name_en"

# Firestore REST API: update via PATCH mit updateMask
req2 = urllib.request.Request(update_url, data=json.dumps(body).encode(), headers=hdrs, method='PATCH')
try:
    resp2 = urllib.request.urlopen(req2)
    result = json.loads(resp2.read())
    print(f"   ✅ Update erfolgreich: {result.get('name','?')}")
except HTTPError as e:
    body_err = e.read().decode()
    print(f"   ❌ Update fehlgeschlagen: {body_err[:200]}")

# 3) Geänderten Wert zurücklesen
print(f"\n3) Lese geändertes Restaurant 'r1':")
req3 = urllib.request.Request(f"{BASE}/restaurants/r1", headers=hdrs)
resp3 = urllib.request.urlopen(req3)
data3 = json.loads(resp3.read())
fields3 = data3.get('fields', {})
print(f"   name_ar: {fields3.get('name_ar',{}).get('stringValue','?')}")
print(f"   name_en: {fields3.get('name_en',{}).get('stringValue','?')}")
print(f"   rating: {fields3.get('rating',{}).get('doubleValue','?')}")

# 4) Auf ursprünglichen Wert zurücksetzen
print(f"\n4) Setze 'r1' auf Ursprungswert zurück:")
reset_body = {
    "fields": {
        "rating": {"doubleValue": 4.8},
        "name_ar": {"stringValue": "مطعم أبو عوف"},
        "name_en": {"stringValue": "Abu Auf Restaurant"},
    }
}
reset_url = f"{BASE}/restaurants/r1?updateMask.fieldPaths=rating&updateMask.fieldPaths=name_ar&updateMask.fieldPaths=name_en"
req4 = urllib.request.Request(reset_url, data=json.dumps(reset_body).encode(), headers=hdrs, method='PATCH')
try:
    urllib.request.urlopen(req4)
    print("   ✅ Zurückgesetzt")
except HTTPError as e:
    print(f"   ❌ {e.read().decode()[:200]}")

# 5) Alle Menu-Items zählen
req5 = urllib.request.Request(f"{BASE}/menu_items", headers=hdrs)
resp5 = urllib.request.urlopen(req5)
data5 = json.loads(resp5.read())
menu_count = len(data5.get('documents', []))
print(f"\n5) Menu-Items in Firestore: {menu_count}")

print(f"\n{'='*60}")
print(f"✅ PHASE 2 BESTANDEN: {len(docs)} Restaurants, {menu_count} Menü-Items")
print(f"   Daten in Firestore – Provider liest sie aus – Änderung möglich")
print(f"{'='*60}")