import pykakasi

kks = pykakasi.kakasi()

reading='サツ'
reading = kks.convert(reading)[0]['hira']
print(reading)