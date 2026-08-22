#!/usr/bin/env python3
"""
Seed: Lädt Demo-Restaurants und Menü-Items in Firestore.
Nutzt den Firebase-CLI-Login-Token des Users.
"""
import json, os, sys, urllib.request

CONFIG_PATH = os.path.expanduser('~/.config/configstore/firebase-tools.json')
PROJECT_ID = 'tawali-2ded4'
COLL_BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

def load_token():
    config = json.load(open(CONFIG_PATH))
    return config['tokens']['access_token']

def headers(token):
    return {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

def fs_val(val):
    """Konvertiert Python-Wert in Firestore-Feld-Value."""
    if isinstance(val, bool):
        return {'booleanValue': val}
    elif isinstance(val, int):
        return {'integerValue': str(val)}
    elif isinstance(val, float):
        return {'doubleValue': val}
    elif isinstance(val, str):
        return {'stringValue': val}
    elif val is None:
        return {'nullValue': None}
    elif isinstance(val, list):
        return {'arrayValue': {'values': [fs_val(v) for v in val]}}
    elif isinstance(val, dict):
        return {'mapValue': {'fields': {k: fs_val(v) for k, v in val.items()}}}
    return {'stringValue': str(val)}

def upload_doc(collection, doc_id, data, token):
    """Legt ein Dokument in Firestore an (Überschreiben bei existierendem)."""
    fields = {k: fs_val(v) for k, v in data.items()}
    body = json.dumps({'fields': fields})
    url = f"{COLL_BASE}/{collection}?documentId={doc_id}"
    hdrs = headers(token)
    
    try:
        req = urllib.request.Request(url, data=body.encode(), headers=hdrs, method='POST')
        resp = urllib.request.urlopen(req)
        result = json.loads(resp.read())
        name = result.get('name', '?')
        print(f"  ✅ {collection}/{doc_id}")
        return True
    except urllib.request.HTTPError as e:
        body_text = e.read().decode()
        print(f"  ❌ {collection}/{doc_id}: {body_text[:150]}")
        return False
    except Exception as e:
        print(f"  ❌ {collection}/{doc_id}: {str(e)[:150]}")
        return False

# -----------------------------------------------------------------------
#  Demo-Daten
# -----------------------------------------------------------------------
RESTAURANTS = [
    {"id":"r1","name_ar":"مطعم أبو عوف","name_en":"Abu Auf Restaurant","description_ar":"أشهر مطعم سوداني في الخرطوم","category":"sudanese","phone":"0912345001","whatsapp":"24912345001","address":"شارع النيل، الخرطوم","district":"الرياض","lat":15.603,"lng":32.5261,"rating":4.8,"review_count":342,"delivery_fee":2.5,"min_order":5.0,"delivery_time_min":20,"delivery_time_max":35,"is_active":True,"is_featured":True,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r2","name_ar":"مطبخ الكوثر","name_en":"Al Kawthar Kitchen","description_ar":"مطبخ سوداني أصيل","category":"sudanese","phone":"0912345002","whatsapp":"24912345002","address":"شارع العرضة، أم درمان","district":"أم درمان","lat":15.6502,"lng":32.4808,"rating":4.6,"review_count":215,"delivery_fee":3.0,"min_order":8.0,"delivery_time_min":25,"delivery_time_max":45,"is_active":True,"is_featured":True,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r3","name_ar":"بيتزا الزعيم","name_en":"Al Za'eem Pizza","description_ar":"بيتزا على الطريقة الإيطالية والسودانية","category":"pizza","phone":"0912345003","address":"شارع المطار، الخرطوم","district":"الخرطوم 2","lat":15.589,"lng":32.538,"rating":4.5,"review_count":187,"delivery_fee":3.5,"min_order":12.0,"delivery_time_min":20,"delivery_time_max":30,"is_active":True,"is_featured":True,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r4","name_ar":"فول وفلافل النيل","name_en":"Nile Ful & Falafel","description_ar":"أفخم فول وفلافل في السودان","category":"sudanese","phone":"0912345004","address":"شارع النيل، الخرطوم","district":"الرياض","lat":15.601,"lng":32.524,"rating":4.7,"review_count":298,"delivery_fee":2.0,"min_order":3.0,"delivery_time_min":15,"delivery_time_max":25,"is_active":True,"is_featured":True,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r5","name_ar":"مشاوي الخرطوم","name_en":"Khartoum Grill","description_ar":"أفضل المشاوي في الخرطوم","category":"middle_eastern","phone":"0912345005","whatsapp":"24912345005","address":"شارع السيد عبد الرحمن، الخرطوم","district":"السجانة","lat":15.595,"lng":32.545,"rating":4.9,"review_count":421,"delivery_fee":4.0,"min_order":15.0,"delivery_time_min":30,"delivery_time_max":50,"is_active":True,"is_featured":True,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r6","name_ar":"مطعم السودان","name_en":"Sudan Restaurant","description_ar":"مطعم سوداني تقليدي","category":"sudanese","phone":"0912345006","address":"شارع الوادي، بحري","district":"بحري","lat":15.626,"lng":32.514,"rating":4.4,"review_count":156,"delivery_fee":3.0,"min_order":8.0,"delivery_time_min":25,"delivery_time_max":40,"is_active":True,"is_featured":False,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r7","name_ar":"برجر كينق السودان","name_en":"Burger King Sudan","description_ar":"برجر لحم و دجاج بجودة عالية","category":"fast_food","phone":"0912345007","address":"أفريقيا شارع، الخرطوم","district":"المعمورة","lat":15.578,"lng":32.551,"rating":4.3,"review_count":134,"delivery_fee":3.5,"min_order":10.0,"delivery_time_min":20,"delivery_time_max":35,"is_active":True,"is_featured":False,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r8","name_ar":"حلويات رمضان","name_en":"Ramadan Sweets","description_ar":"أشهى الحلويات والكنافة والقطايف","category":"dessert","phone":"0912345008","address":"شارع السوق، أم درمان","district":"السوق الشعبي","lat":15.648,"lng":32.483,"rating":4.6,"review_count":203,"delivery_fee":2.5,"min_order":5.0,"delivery_time_min":15,"delivery_time_max":25,"is_active":True,"is_featured":False,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r9","name_ar":"مقهى النيل","name_en":"Nile Cafe","description_ar":"قهوة سودانية أصيلة ومشروبات منعشة","category":"cafe","phone":"0912345009","address":"كورنيش النيل، الخرطوم","district":"المنشية","lat":15.599,"lng":32.505,"rating":4.2,"review_count":98,"delivery_fee":2.0,"min_order":3.0,"delivery_time_min":10,"delivery_time_max":20,"is_active":True,"is_featured":False,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
    {"id":"r10","name_ar":"مطعم الشرق","name_en":"Al Sharq Restaurant","description_ar":"مأكولات شرق أوسطية وعربية","category":"middle_eastern","phone":"0912345010","whatsapp":"24912345010","address":"شارع الجمهورية، الخرطوم","district":"برّي","lat":15.586,"lng":32.562,"rating":4.7,"review_count":276,"delivery_fee":3.5,"min_order":12.0,"delivery_time_min":25,"delivery_time_max":45,"is_active":True,"is_featured":True,"accepts_cod":True,"accepts_mobile_money":True,"created_at":"2026-08-01T00:00:00Z","updated_at":"2026-08-01T00:00:00Z"},
]

MENU_ITEMS = [
    {"id":"m1_1","restaurant_id":"r1","name_ar":"فول مدمس","name_en":"Ful Medames","description_ar":"فول مدمس بالزبدة والكمون","category":"main","price":3.5,"is_available":True,"is_popular":True,"preparation_time_min":10},
    {"id":"m1_2","restaurant_id":"r1","name_ar":"فلافل","name_en":"Falafel","description_ar":"فلافل مقلية طازجة مع الطحينة","category":"appetizer","price":2.0,"is_available":True,"is_popular":True,"preparation_time_min":10},
    {"id":"m1_3","restaurant_id":"r1","name_ar":"بطاطس مقلية","name_en":"French Fries","description_ar":"بطاطس مقلية ذهبية","category":"side","price":1.5,"is_available":True,"is_popular":False,"preparation_time_min":8},
    {"id":"m1_4","restaurant_id":"r1","name_ar":"طعمية","name_en":"Ta'meya","description_ar":"طعمية مصرية","category":"appetizer","price":2.5,"is_available":True,"is_popular":False,"preparation_time_min":12},
    {"id":"m2_1","restaurant_id":"r2","name_ar":"عصيدة","name_en":"Asida","description_ar":"عصيدة سودانية مع الملاح","category":"main","price":6.0,"is_available":True,"is_popular":True,"preparation_time_min":20},
    {"id":"m2_2","restaurant_id":"r2","name_ar":"ملاح","name_en":"Mullah","description_ar":"ملاح سوداني بالبامية واللحم","category":"main","price":7.0,"is_available":True,"is_popular":True,"preparation_time_min":25},
    {"id":"m2_3","restaurant_id":"r2","name_ar":"شوربة عدس","name_en":"Lentil Soup","description_ar":"شوربة عدس بالكمون","category":"appetizer","price":3.0,"is_available":True,"is_popular":False,"preparation_time_min":15},
    {"id":"m2_4","restaurant_id":"r2","name_ar":"كسرة","name_en":"Kisra","description_ar":"كسرة سودانية","category":"side","price":4.0,"is_available":True,"is_popular":False,"preparation_time_min":15},
    {"id":"m3_1","restaurant_id":"r3","name_ar":"بيتزا مارجريتا","name_en":"Margherita Pizza","description_ar":"بيتزا بجبنة الموزاريلا","category":"main","price":12.0,"is_available":True,"is_popular":True,"preparation_time_min":20},
    {"id":"m3_2","restaurant_id":"r3","name_ar":"بيتزا سودانية","name_en":"Sudanese Pizza","description_ar":"بيتزا باللحم والبهارات السودانية","category":"main","price":14.0,"is_available":True,"is_popular":True,"preparation_time_min":25},
    {"id":"m3_3","restaurant_id":"r3","name_ar":"بيتزا دجاج","name_en":"Chicken Pizza","description_ar":"بيتزا بقطع الدجاج","category":"main","price":13.0,"is_available":True,"is_popular":False,"preparation_time_min":22},
    {"id":"m4_1","restaurant_id":"r4","name_ar":"فول مدمس بالزبدة","name_en":"Ful with Butter","description_ar":"فول مدمس بالزبدة السودانية","category":"main","price":4.0,"is_available":True,"is_popular":True,"preparation_time_min":10},
    {"id":"m4_2","restaurant_id":"r4","name_ar":"فلافل مشكل","name_en":"Mixed Falafel","description_ar":"فلافل متنوعة","category":"appetizer","price":3.0,"is_available":True,"is_popular":True,"preparation_time_min":12},
    {"id":"m4_3","restaurant_id":"r4","name_ar":"عصير تمر هندي","name_en":"Tamarind Juice","description_ar":"عصير طبيعي منعش","category":"drink","price":2.0,"is_available":True,"is_popular":False,"preparation_time_min":5},
    {"id":"m5_1","restaurant_id":"r5","name_ar":"كباب","name_en":"Kebab","description_ar":"كباب لحم غنم على الفحم","category":"main","price":18.0,"is_available":True,"is_popular":True,"preparation_time_min":30},
    {"id":"m5_2","restaurant_id":"r5","name_ar":"شيش طاووق","name_en":"Shish Tawook","description_ar":"شيش طاووق دجاج متبل","category":"main","price":15.0,"is_available":True,"is_popular":True,"preparation_time_min":25},
    {"id":"m5_3","restaurant_id":"r5","name_ar":"كفتة","name_en":"Kofta","description_ar":"كفتة لحم مفروم","category":"main","price":14.0,"is_available":True,"is_popular":False,"preparation_time_min":25},
    {"id":"m5_4","restaurant_id":"r5","name_ar":"مقانق","name_en":"Makanek","description_ar":"مقانق لحم ببهارات خاصة","category":"appetizer","price":10.0,"is_available":True,"is_popular":False,"preparation_time_min":20},
    {"id":"m6_1","restaurant_id":"r6","name_ar":"كبسة","name_en":"Kabsa","description_ar":"كبسة لحم أو دجاج","category":"main","price":12.0,"is_available":True,"is_popular":True,"preparation_time_min":35},
    {"id":"m6_2","restaurant_id":"r6","name_ar":"شوربة عدس","name_en":"Lentil Soup","description_ar":"شوربة عدس","category":"appetizer","price":3.5,"is_available":True,"is_popular":False,"preparation_time_min":15},
    {"id":"m6_3","restaurant_id":"r6","name_ar":"سلطة خضراء","name_en":"Green Salad","description_ar":"سلطة خضار طازجة","category":"side","price":2.5,"is_available":True,"is_popular":False,"preparation_time_min":5},
    {"id":"m7_1","restaurant_id":"r7","name_ar":"برجر لحم","name_en":"Beef Burger","description_ar":"برجر لحم بقري مع البطاطس","category":"main","price":10.0,"is_available":True,"is_popular":True,"preparation_time_min":15},
    {"id":"m7_2","restaurant_id":"r7","name_ar":"برجر دجاج","name_en":"Chicken Burger","description_ar":"برجر صدر دجاج مقرمش","category":"main","price":9.0,"is_available":True,"is_popular":True,"preparation_time_min":15},
    {"id":"m7_3","restaurant_id":"r7","name_ar":"بطاطس","name_en":"Fries","description_ar":"بطاطس مقلية","category":"side","price":2.0,"is_available":True,"is_popular":False,"preparation_time_min":8},
    {"id":"m8_1","restaurant_id":"r8","name_ar":"كنافة","name_en":"Kunafa","description_ar":"كنافة ناعمة بالجبنة","category":"main","price":6.0,"is_available":True,"is_popular":True,"preparation_time_min":15},
    {"id":"m8_2","restaurant_id":"r8","name_ar":"قطايف","name_en":"Qatayef","description_ar":"قطايف بالقشطة والمكسرات","category":"main","price":5.0,"is_available":True,"is_popular":True,"preparation_time_min":20},
    {"id":"m8_3","restaurant_id":"r8","name_ar":"بسبوسة","name_en":"Basbousa","description_ar":"بسبوسة بجوز الهند","category":"main","price":4.0,"is_available":True,"is_popular":False,"preparation_time_min":12},
    {"id":"m9_1","restaurant_id":"r9","name_ar":"قهوة سودانية","name_en":"Sudanese Coffee","description_ar":"قهوة سودانية أصيلة","category":"drink","price":2.0,"is_available":True,"is_popular":True,"preparation_time_min":5},
    {"id":"m9_2","restaurant_id":"r9","name_ar":"شاي كرك","name_en":"Karak Tea","description_ar":"شاي كرك بالحليب","category":"drink","price":2.0,"is_available":True,"is_popular":True,"preparation_time_min":5},
    {"id":"m9_3","restaurant_id":"r9","name_ar":"عصير مانجو","name_en":"Mango Juice","description_ar":"عصير مانجو طازج","category":"drink","price":3.0,"is_available":True,"is_popular":False,"preparation_time_min":7},
    {"id":"m10_1","restaurant_id":"r10","name_ar":"مندي لحم","name_en":"Mandi Meat","description_ar":"مندي لحم مع الأرز","category":"main","price":15.0,"is_available":True,"is_popular":True,"preparation_time_min":35},
    {"id":"m10_2","restaurant_id":"r10","name_ar":"كبسة دجاج","name_en":"Kabsa Chicken","description_ar":"كبسة دجاج","category":"main","price":13.0,"is_available":True,"is_popular":True,"preparation_time_min":30},
    {"id":"m10_3","restaurant_id":"r10","name_ar":"محشي","name_en":"Mahshi","description_ar":"محشي ورق عنب","category":"main","price":8.0,"is_available":True,"is_popular":False,"preparation_time_min":30},
]

if __name__ == '__main__':
    token = load_token()
    
    print("=" * 60)
    print("SEED: Lade Demo-Daten in Firestore")
    print("=" * 60)
    
    ok = 0
    fail = 0
    
    print(f"\n--- Restaurants ({len(RESTAURANTS)}) ---")
    for r in RESTAURANTS:
        data = {k: v for k, v in r.items() if k != 'id'}
        if upload_doc('restaurants', r['id'], data, token):
            ok += 1
        else:
            fail += 1
    
    print(f"\n--- Menu Items ({len(MENU_ITEMS)}) ---")
    for m in MENU_ITEMS:
        data = {k: v for k, v in m.items() if k != 'id'}
        if upload_doc('menu_items', m['id'], data, token):
            ok += 1
        else:
            fail += 1
    
    print(f"\n{'='*60}")
    print(f"Fertig: {ok} OK, {fail} fehlgeschlagen")
    print(f"{'='*60}")
    sys.exit(0 if fail == 0 else 1)