from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QFrame, QScrollArea, QPushButton, QGridLayout
from PyQt6.QtCore import Qt, QSize, QTimer
import sys
import test

class MainWindow(QWidget):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # set the window title
        self.setWindowTitle('漢単 - Kantan')

        loadN1Bttn = QPushButton('N1')
        loadN2Bttn = QPushButton('N2')
        loadN3Bttn = QPushButton('N3')

        loadN4Bttn = QPushButton('N4')
        loadN4Bttn.clicked.connect(lambda: self.addKanjiWidget(4))

        layout = QGridLayout()
        self.setLayout(layout)

        layout.addWidget(loadN4Bttn)
        
        self.show()

    def addKanjiWidget(self, level):
        widget = showKanji2(level)
        self.layout().addWidget(widget)
        #self.button.setEnabled(False)

class showKanji2(QWidget):
    def __init__(self, level, num=10):
        super().__init__()
        self.kanji_list = test.getByJlpt(level)
        self.kanji_num = num
        self.current_page = 0

        layout = QVBoxLayout()
        self.kanji_container = QGridLayout()

        label = QLabel('hi')

        scroll = QScrollArea(self)
        scroll.setWidgetResizable(True)
        scroll.setWidget(self.kanji_container)

        layout.addWidget(label)
        layout.addWidget(scroll)

        self.setLayout(layout)
        self.load_items()

    def load_items(self):
        start = self.current_page * self.kanji_num
        end = start + self.kanji_num
        new_kanji = self.kanji_list[start:end]

        for kanji in new_kanji:
            label = QLabel(kanji)
            self.kanji_container().addWidget(label)
        

class showKanji(QWidget):
    def __init__(self, level, kanji_num=10):
        super().__init__()

        self.kanji_list = test.getByJlpt(level)
        self.kanji_num = kanji_num
        self.current_page = 0
        
        # Main Layout
        self.layout = QGridLayout(self)
        
        # Scroll Area setup
        self.scroll_area = QScrollArea(self)
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setWidget(self)
        
        self.container_layout = QVBoxLayout()  # This layout will hold all the label boxes
        self.layout.addWidget(self.scroll_area)

        self.setLayout(self.layout)

        self.load_items()
        
        # Infinite Scroll setup
        self.scroll_area.verticalScrollBar().valueChanged.connect(self.on_scroll)

    def load_items(self):
        # Load a subset of the items for the current page
        start = self.current_page * self.kanji_num
        end = start + self.kanji_num
        new_kanji = self.kanji_list[start:end]

        for kanji in new_kanji:
            box = self.kanji_tile(kanji)
            self.container_layout.addWidget(box)
        
        self.setLayout(self.layout)

    def kanji_tile(self, text):
        frame = QFrame(self)
        frame.setFrameShape(QFrame.Box)
        frame.setFrameShadow(QFrame.Sunken)
        frame.setLineWidth(2)
        frame.setStyleSheet("background-color: lightgray; padding: 10px;")
        
        label = QLabel(text, frame)
        label.setAlignment(Qt.AlignCenter)
        frame.setLayout(QVBoxLayout())
        frame.layout().addWidget(label)

        return frame
    
    def on_scroll(self):
        """Checks if the user has scrolled to the bottom, and if so, load more items."""
        scroll_bar = self.scroll_area.verticalScrollBar()
        if scroll_bar.value() == scroll_bar.maximum():
            # User has scrolled to the bottom
            self.current_page += 1
            if self.current_page * self.kanji_num < len(self.kanji_list):
                self.load_items()

if __name__ == '__main__':
    app = QApplication(sys.argv)

    # create the main window
    window = MainWindow()

    # start the event loop
    sys.exit(app.exec())