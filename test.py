import json
import random
import pykakasi

kks = pykakasi.kakasi()

kradfile_path = 'dict/kradfile-3.6.1.json'
kanjidic_path = 'dict/kanjidic2-all-3.6.1.json'
userdata_path = 'user.json'


try:
    with open(f'{kradfile_path}', 'r') as f:
        kradfile = json.load(f)
    
except FileNotFoundError:
    print("Error: The file 'kradfile-3.6.1.json' was not found.")

try:
    with open(f'{kanjidic_path}', 'r') as f:
        kanjidic = json.load(f)
    
except FileNotFoundError:
    print("Error: The file 'kradfile-3.6.1.json' was not found.")



def getByJlpt(level):
    data = []

    for chara in kanjidic['characters']:
        jlpt = chara['misc']['jlptLevel']
        if jlpt == level:
            txt = chara['literal']
            data.append(txt)

    return data

def getByStrokeNo(level):
    data = []

    for chara in kanjidic['characters']:
        jlpt = chara['misc']['strokeCounts']
        if jlpt == level:
            txt = chara['literal']
            data.append(txt)

    return data

def getRadicalByJlpt(level):
    jlpt_kanji = getByJlpt(level)
    radicals = []
    jlpt_radicals = []

    for chara in kradfile['kanji']:
        for radical in kradfile['kanji'][f'{chara}']:
            radicals.append(radical)

    for kanji in jlpt_kanji:
        if kanji in radicals:
            jlpt_radicals.append(kanji)

    return jlpt_radicals

# for single characters in kanjidic2
def showKanjiData(kanji):
    data = {}
    for chara in kanjidic['characters']:
        if chara['literal'] == kanji:
            #print(f'\n=========\n{chara['literal']}:')
            data['on'] = []
            data['meaning'] = []
            for reading in chara['readingMeaning']['groups'][0]['readings']:
                if reading['type'] == 'ja_on':
                    #print(f'on > {reading['value']}')
                    data['on'].append(reading['value'])
                #if reading['type'] == 'ja_kun':
                    #print(f'kun > {reading['value']}')
            for meaning in chara['readingMeaning']['groups'][0]['meanings']:
                if meaning['lang'] == 'en':
                     data['meaning'].append(meaning['value'])
                    #print(f'meaning: {meaning['value']}')
    return data
             

showKanjiData(getRadicalByJlpt(4))

def learn():
    # determine the frequency of what gets shown
    # 3. single vs compound kanji (total num of known kanji + word type)
    # 1. on reading proficiency
    # 2. kun reading proficiency(?) (might have verb conjugation as well)
    # I need to deal with specific reading/meaning pairs

    with open(f'{userdata_path}', 'r') as f:
        userdata = json.load(f)
    
    user_set = userdata['userset']
    current_set = getByJlpt(userdata['jlpt_level'])
    q_type = ['to on', 'to kun', 'meaning']

    playing = True
    while playing:
        i = random.randrange(0, len(current_set))
        #q_i = random.randint(0,2)
        q_i = 0

        cur_kanj = current_set[i]
        
        # ask the user for an onyomi reading
        if q_i == 0:
            kanji_data = showKanjiData(cur_kanj)
            r_i = random.randint(0, len(kanji_data['on'])-1)
            reading = kanji_data['on'][r_i]
            print(f'\n=======\nWhat is the onyomi reading of {cur_kanj}?')
            if len(kanji_data['on'])-1 > 1:
                alt_readings = kanji_data['on']
                del alt_readings[r_i]
                print(f'not {alt_readings}')

        usrans = input('ans (type q to quit): ')
        if usrans.lower() == 'q':
            playing = False
        elif usrans == kks.convert(reading)[0]['hepburn']:
            print(f'{reading} | correct!')
        else:
            print(f'wrong\nans: {reading}')

learn()