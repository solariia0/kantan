import json
import random
import pykakasi
import db

kks = pykakasi.kakasi()

kradfile_path = 'kantan/dict/kradfile-3.6.1.json'
kanjidic_path = 'kantan/dict/kanjidic2-all-3.6.1.json'
userdata_path = 'kantan/user.json'


try:
    with open(f'{kradfile_path}', 'r', encoding='utf-8') as f:
        kradfile = json.load(f)
    
except FileNotFoundError:
    print("Error: The file 'kradfile-3.6.1.json' was not found.")

try:
    with open(f'{kanjidic_path}', 'r', encoding='utf-8') as f:
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

def getByStrokeNo(num):
    data = []

    for chara in kanjidic['characters']:
        count = chara['misc']['strokeCounts'][0]
        if count == num:
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
            data['on'] = []
            data['kun'] = []
            data['meaning'] = []
            for reading in chara['readingMeaning']['groups'][0]['readings']:
                if reading['type'] == 'ja_on':
                    data['on'].append(reading['value'])
                if reading['type'] == 'ja_kun':
                    data['kun'].append(reading['value'])
            for meaning in chara['readingMeaning']['groups'][0]['meanings']:
                if meaning['lang'] == 'en':
                     data['meaning'].append(meaning['value'])
    return data

# if userset is empty show rand radicals in n4
# else:
# use stroke count to sort radicals into groups
# give radicals points
# intoduce 

def learn():
    # determine the frequency of what gets shown
    # 3. single vs compound kanji (total num of known kanji + word type)
    # 1. on reading proficiency
    # 2. kun reading proficiency(?) (might have verb conjugation as well)
    # I need to deal with specific reading/meaning pairs

    try:
        with open(f'{userdata_path}', 'r') as f:
            userdata = json.load(f)
        
    except FileNotFoundError:
        print("Error: The file 'user.json' was not found.")

    
    user_set = userdata['userset']
    current_set = getByJlpt(userdata['jlpt_level'])
    q_type = ['to on', 'to kun', 'meaning']

    playing = True
    while playing:
        k_type = 'single'
        i = random.randrange(0, len(current_set))
        #q_i = random.randint(0,2)
        q_i = 2

        curkanji = current_set[i]
        
        # ask the user for an onyomi reading
        if q_type[q_i] == 'to on':
            kanji_data = showKanjiData(curkanji)
            # index of asked reading
            r_i = random.randint(0, len(kanji_data['on'])-1)
            reading = kanji_data['on'][r_i]
            ans = reading

            print(f'\n=======\nWhat is the onyomi reading of {curkanji}?')
            if len(kanji_data['on'])-1 > 1:
                alt_readings = kanji_data['on']
                del alt_readings[r_i]
                print(f'not {alt_readings}')
        #kunyomi
        elif q_type[q_i] == 'to kun':
            kanji_data = showKanjiData(curkanji)
            # index of asked reading
            r_i = random.randint(0, len(kanji_data['kun'])-1)
            reading = kanji_data['kun'][r_i]
            ans = reading

            print(f'\n=======\nWhat is the kunyomi reading of {curkanji}?')
            if len(kanji_data['kun'])-1 > 1:
                alt_readings = kanji_data['kun']
                del alt_readings[r_i]
                print(f'not {alt_readings}')
        elif q_type[q_i] == 'meaning':
            kanji_data = showKanjiData(curkanji)
            # index of asked reading
            r_i = random.randint(0, len(kanji_data['meaning'])-1)
            reading = kanji_data['meaning'][r_i]
            ans = reading

            print(f'\n=======\nWhat is the meaning reading of {curkanji}?')
            if len(kanji_data['meaning'])-1 > 1:
                alt_readings = kanji_data['meaning']
                del alt_readings[r_i]
                print(f'not {alt_readings}')

        usrans = input('ans (type q to quit): ')
        if usrans.lower() == 'q':
            playing = False
            break
        elif usrans == kks.convert(ans)[0]['hepburn']:
            print(f'{ans} | correct!')
            correct = True
        else:
            print(f'wrong\nans: {ans}')
            correct = False

        userdata['userset'] = updateUserSet(
            k_type,
            q_type[q_i],
            usrans,
            correct,
            curkanji,
            ans,
            user_set
        )

        json_str = json.dumps(userdata, indent=4, ensure_ascii=False)
        with open(userdata_path, "w", encoding='utf8') as f:
            f.write(json_str)


def updateUserSet(k_type, q_type, usrans, correct, curkanji, ans, userset):
    if curkanji in userset:
        entry = userset[curkanji]
        entry['last_try'] = None # add timestamp functionality
        entry['last_q_type'] = q_type
        if correct:
            entry[q_type][ans]['right'] += int(correct)
        else:
            if 'attempts' in entry[q_type][ans]:
                entry[q_type][ans]['attempts'].append(usrans)
            else:
                entry[q_type][ans]['attempts'] = [usrans]
    else:
        entry = {}
        entry['type'] = k_type
        entry['last_try'] = None # add timestamp functionality
        entry['last_q_type'] = q_type
        entry[q_type] = {ans: {"wrong": 0, "right":0}}
        if correct:
            entry[q_type][ans]['right'] += 1
        else:
            entry[q_type][ans]['wrong'] += 1
            entry[q_type][ans]['attempts'] = usrans # Conversion doesn't work 
        userset[curkanji] = entry
    return userset


# dynamically update the values to be studied

# show (num of radicals) 2, then show 2 - 3 kanji (limit all at 5)
# if sum(usr_kanji) == 10 start showing compounds

def learn2():
    radicals = getRadicalByJlpt(4)
    rad_to_show = 2
    kanj_to_show = 3
    i = 0

    usr_radical = {}
    temp_set = {'radicals': [], 'kanji': []}

    while i < rad_to_show:
        radical = radicals[random.randint(0, len(radicals) - 1)]
        

        #to_on(radical)
        kanji_data = showKanjiData(radical)
        # index of asked reading
        r_i = random.randint(0, len(kanji_data['on'])-1)
        reading = kanji_data['on'][r_i]
        ans = reading

        print(f'\n=======\nWhat is the onyomi reading of {radical}?')
        print(showKanjiData(radical)) # show both then test
        if len(kanji_data['on']) > 1:
            alt_readings = kanji_data['on']
            del alt_readings[r_i]
            print(f'not {alt_readings}')

        #correct = checkAns(usrans)
        usrans = input('ans (type q to quit): ')
        if usrans.lower() == 'q':
            playing = False
            break
        elif usrans == kks.convert(ans)[0]['hepburn']:
            print(f'{ans} | correct!')
            correct = True
        else:
            print(f'wrong\nans: {ans}')
            correct = False

        if radical in usr_radical:
            if correct:
                usr_radical[f'{radical}'][f'{ans}']['right'] += 1
            else:
                usr_radical[f'{radical}'][f'{ans}']['wrong'] += 1
        else:
            if correct:
                usr_radical[f'{radical}'] = {
                    f'{ans}': {'right': 1, 'wrong': 0}
                    }
            else:
                usr_radical[f'{radical}'] = {
                    f'{ans}': {'right': 0, 'wrong': 1}
                    }
        temp_set['radicals'].append(radical)
        print(usr_radical)
        print(temp_set)
        i += 1


    i = 0

    kanji_set = getByStrokeNo(5)
    for char in kanji_set:
        for rad in temp_set['radicals']:
            if char in kradfile['kanji'] and rad in kradfile['kanji'][f'{char}']:
                temp_set['kanji'].append(char)

    print('=======')
    print(temp_set)

    while i < kanj_to_show:
        cur_kanji = temp_set['kanji'][random.randint(0, len(temp_set['kanji'])-1)]
        # check if it's been added and mark it in db
        # query the kanji entr id
        # { attempts: []}
        # add it to temporary set


        kanji_data = showKanjiData(cur_kanji)
        # index of asked reading
        r_i = random.randint(0, len(kanji_data['on'])-1)
        reading = kanji_data['on'][r_i]
        ans = reading

        print(f'\n=======\nWhat is the onyomi reading of {cur_kanji}?')
        print(showKanjiData(cur_kanji)) # show both then test
        if len(kanji_data['on']) > 1:
            alt_readings = kanji_data['on']
            del alt_readings[r_i]
            print(f'not {alt_readings}')

        #correct = checkAns(usrans)
        usrans = input('ans (type q to quit): ')
        if usrans.lower() == 'q':
            playing = False
            break
        elif usrans == kks.convert(ans)[0]['hepburn']:
            print(f'{ans} | correct!')
            correct = True
        else:
            print(f'wrong\nans: {ans}')
            correct = False

        db.findKanji(cur_kanji, ans) # if this returns none still add just locally
        i += 1

    # query to see if compound target has been hit
    compound_on = True

    if compound_on:
        comp_to_show = 2
        i = 0
        while i < comp_to_show:
            # query db based on kanji in temp + known kanji
            compound = 'something'
            #print(showKanjiData(kanji))
            # check if it's been added and mark it in db
            # add it to temporary set
            i += 1


learn2()


def to_on(curkanji):
    kanji_data = showKanjiData(curkanji)
    # index of asked reading
    r_i = random.randint(0, len(kanji_data['on'])-1)
    reading = kanji_data['on'][r_i]
    ans = reading

    print(f'\n=======\nWhat is the onyomi reading of {curkanji}?')
    if len(kanji_data['on'])-1 > 1:
        alt_readings = kanji_data['on']
        del alt_readings[r_i]
        print(f'not {alt_readings}')

