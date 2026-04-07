with open('jlpt.txt', "r", encoding='utf-8') as j:
            for line in j:
                line = line.strip()
                if "n" in line:
                        level = line[1:]
                        print(level)
                    