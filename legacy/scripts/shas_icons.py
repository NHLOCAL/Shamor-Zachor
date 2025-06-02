import flet as ft

def main(page: ft.Page):
    page.title = "אייקונים למסכתות הש\"ס"
    page.rtl = True

    grid = ft.GridView(
        expand=True,
        runs_count=5,
        max_extent=150,
        child_aspect_ratio=1.0,
        spacing=5,
        run_spacing=5,
    )

    maschtot = {
        #"ברכות": ft.icons.SUNRISE,
        "שבת": ft.icons.CANDLESTICK_CHART,
        "עירובין": ft.icons.FENCE, 
        "פסחים": ft.icons.FAMILY_RESTROOM,
        "שקלים": ft.icons.ATTACH_MONEY,
        "יומא": ft.icons.PETS,
        "סוכה": ft.icons.CABIN, 
        "ביצה": ft.icons.EGG,
        "ראש השנה": ft.icons.MUSIC_NOTE,
        #"תענית": ft.icons.FACE_SAD,
        #"מגילה": ft.icons.SCROLL,
        "מועד קטן": ft.icons.CELEBRATION,
        "חגיגה": ft.icons.WINE_BAR, 
        "יבמות": ft.icons.GROUPS,
        "כתובות": ft.icons.FAVORITE,
        "נדרים": ft.icons.CHILD_CARE,
        "נזיר": ft.icons.CUT,
        "סוטה": ft.icons.WATER_DROP,
        "גיטין": ft.icons.ARTICLE,
        "קידושין": ft.icons.FAVORITE,
        #"בבא קמא": ft.icons.HAMMER, 
        "בבא מציעא": ft.icons.HANDSHAKE, "בבא בתרא": ft.icons.MONEY, "סנהדרין": ft.icons.GAVEL, "מכות": ft.icons.WARNING,
        #"שבועות": ft.icons.HAND_UP,
        "עדיות": ft.icons.REMOVE_RED_EYE, "עבודה זרה": ft.icons.DO_NOT_DISTURB_ON, 
        "אבות": ft.icons.PEOPLE,
        "הוריות": ft.icons.WARNING,
        "חולין": ft.icons.FASTFOOD,
    }
    
    
    """ icons = [
        # סדר זרעים
        (ft.icons.SUNNY, "ברכות"),
        (ft.icons.AGRICULTURE, "פאה"),
        (ft.icons.QUESTION_MARK, "דמאי"),
        (ft.icons.GRASS, "כלאים"),
        (ft.icons.ECO, "שביעית"),
        (ft.icons.VOLUNTEER_ACTIVISM, "תרומות"),
        (ft.icons.CALCULATE, "מעשרות"),
        (ft.icons.RESTAURANT_MENU, "מעשר שני"),
        (ft.icons.BAKERY_DINING, "חלה"),
        (ft.icons.APPLE, "ערלה"),
        (ft.icons.LOCAL_FLORIST, "ביכורים"),

        # סדר מועד
        (ft.icons.CANDLESTICK_CHART, "שבת"),
        (ft.icons.FENCE, "עירובין"),
        (ft.icons.FAMILY_RESTROOM, "פסחים"),
        (ft.icons.PAYMENTS, "שקלים"),
        (ft.icons.TEMPLE_HINDU, "יומא"),
        (ft.icons.CABIN, "סוכה"),
        (ft.icons.EGG, "ביצה"),
        (ft.icons.CELEBRATION, "ראש השנה"),
        (ft.icons.WATER_DROP, "תענית"),
        (ft.icons.BOOK, "מגילה"),
        (ft.icons.CALENDAR_MONTH, "מועד קטן"),
        (ft.icons.FLIGHT_TAKEOFF, "חגיגה"),

        # סדר נשים
        (ft.icons.FAVORITE, "יבמות"),
        #(ft.icons.WEDDING_BELL, "כתובות"),
        
        #(ft.icons.DIVORCE, "נזיר"),
        (ft.icons.PEOPLE_ALT, "סוטה"),
        (ft.icons.GROUP, "גיטין"),
        (ft.icons.FAMILY_RESTROOM, "קידושין"),

        # ... וכן הלאה עבור שאר המסכתות
    ] """

    for name, icon in maschtot.items():
       grid.controls.append(
            ft.Container(
                content=ft.Column(
                    [
                        ft.Icon(icon, size=30),
                        ft.Text(name, size=12),
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                ),
                alignment=ft.alignment.center,
                padding=10,
                border_radius=5,
                ink=True,
            )
        )

    page.add(grid)

ft.app(target=main)