import flet as ft
from flet import Page
from hebrew_numbers import int_to_gematria

from progress_manager import ProgressManager, get_completed_pages
from data_loader import load_data, get_total_pages, get_completion_date_string

def main(page: Page):
    page.title = "שמור וזכור"
    page.rtl = True
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = ft.Theme(color_scheme_seed=ft.colors.BROWN)
    page.vertical_alignment = ft.MainAxisAlignment.START
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    page.padding = 20
    page.scroll = "adaptive"

    # משתנה לשמירת הכרטיסייה הנוכחית
    current_tab_index = 0
    # משתנה למעקב אחר התצוגה הנוכחית
    current_view = "tracking"  # "tracking" או "books"

    data = load_data()  # נטען את הנתונים בעזרת הפונקציה עם cache
    if not data:
        page.overlay.append(ft.SnackBar(ft.Text("😬 Oops! לא הצלחתי לטעון את הנתונים.")))
        page.update()
        return

    completion_icons = {}
    current_masechta = None

    def update_masechta_completion_status(category: str, masechta_name: str):
        """
        עדכון אייקון השלמה (CHECK או OUTLINED) לצד מסכת או ספר.
        """
        progress = ProgressManager.load_progress(page, masechta_name, category)
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            return False

        total_pages = get_total_pages(masechta_data)
        completed_pages = get_completed_pages(progress, masechta_data["columns"])

        is_completed = (completed_pages == total_pages)
        completion_icons[masechta_name].icon = ft.icons.CHECK_CIRCLE if is_completed else ft.icons.CIRCLE_OUTLINED
        completion_icons[masechta_name].color = ft.colors.GREEN if is_completed else ft.colors.GREY_400
        page.update()

        return is_completed


    def create_table(category: str, masechta_name: str):
        """
        יוצרת טבלת מעקב (DataTable) עבור מסכת/ספר עם עמודים וטופס מעקב.
        """
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            page.overlay.append(ft.SnackBar(ft.Text(f"Error: Masechta '{masechta_name}' not found.")))
            page.update()
            return None

        progress = ProgressManager.load_progress(page, masechta_name, category)
        start_page = masechta_data.get("start_page", 1)

        def on_change(e):
            data = e.control.data
            ProgressManager.save_progress(
                page,
                masechta_name,
                data["daf"],
                data["amud"],
                data["column"],
                e.control.value,
                category,
            )
            update_masechta_completion_status(category, masechta_name)
            update_check_all_status()

        def check_all(e):
            total_pages_ = masechta_data["pages"]
            for row in table.rows:
                for cell in row.cells[1:]:
                    cell.content.value = e.control.value

            ProgressManager.save_all_masechta(
                page, masechta_name, get_total_pages(masechta_data), e.control.value, category
            )
            update_masechta_completion_status(category, masechta_name)
            page.update()

        def update_check_all_status():
            """
            בודק אם כל התיבות מסומנות, ומעדכן את ה-check_all_checkbox.
            """
            all_checked = True
            for row in table.rows:
                for cell in row.cells[1:]:
                    if not cell.content.value:
                        all_checked = False
                        break
                if not all_checked:
                    break
            check_all_checkbox.value = all_checked
            page.update()

        # יצירת כותרות לטבלה
        table_columns = [
            ft.DataColumn(ft.Text(masechta_data["content_type"])),
            ft.DataColumn(ft.Text("לימוד")),
            ft.DataColumn(ft.Text("חזרה 1")),
            ft.DataColumn(ft.Text("חזרה 2")),
            ft.DataColumn(ft.Text("חזרה 3")),
        ]

        table = ft.DataTable(
            columns=table_columns,
            rows=[],
            border=ft.border.all(1, "black"),
            column_spacing=30,
        )

        # מילוי שורות הטבלה
        for i in range(start_page, masechta_data["pages"] + start_page):
            daf_progress = progress.get(str(i), {})
            if masechta_data["content_type"] == "דף":
                # ש"ס - שתי שורות לכל דף
                for amud in ["a", "b"]:
                    amud_symbol = "." if amud == "a" else ":"
                    amud_progress = daf_progress.get(amud, {})
                    row_cells = [
                        ft.DataCell(ft.Text(f"{int_to_gematria(i)}{amud_symbol}")),
                        # גישה לערכים מתוך המילון המקונן
                        ft.DataCell(
                            ft.Checkbox(
                                value=amud_progress.get("learn", False),
                                on_change=on_change,
                                data={
                                    "daf": i,
                                    "amud": amud,
                                    "column": "learn",
                                },
                            )
                        ),
                        ft.DataCell(
                            ft.Checkbox(
                                value=amud_progress.get("review1", False),
                                on_change=on_change,
                                data={
                                    "daf": i,
                                    "amud": amud,
                                    "column": "review1",
                                },
                            )
                        ),
                        ft.DataCell(
                            ft.Checkbox(
                                value=amud_progress.get("review2", False),
                                on_change=on_change,
                                data={
                                    "daf": i,
                                    "amud": amud,
                                    "column": "review2",
                                },
                            )
                        ),
                        ft.DataCell(
                            ft.Checkbox(
                                value=amud_progress.get("review3", False),
                                on_change=on_change,
                                data={
                                    "daf": i,
                                    "amud": amud,
                                    "column": "review3",
                                },
                            )
                        ),
                    ]
                    table.rows.append(ft.DataRow(cells=row_cells))
            else:
                # ספרים אחרים - שורה אחת לכל עמוד/פרק
                row_cells = [
                    ft.DataCell(ft.Text(int_to_gematria(i))),
                    # גישה לערכים מתוך המילון המקונן
                    ft.DataCell(
                        ft.Checkbox(
                            value=daf_progress.get("a", {}).get("learn", False),
                            on_change=on_change,
                            data={"daf": i, "amud": "a", "column": "learn"},
                        )
                    ),
                    ft.DataCell(
                        ft.Checkbox(
                            value=daf_progress.get("a", {}).get("review1", False),
                            on_change=on_change,
                            data={"daf": i, "amud": "a", "column": "review1"},
                        )
                    ),
                    ft.DataCell(
                        ft.Checkbox(
                            value=daf_progress.get("a", {}).get("review2", False),
                            on_change=on_change,
                            data={"daf": i, "amud": "a", "column": "review2"},
                        )
                    ),
                    ft.DataCell(
                        ft.Checkbox(
                            value=daf_progress.get("a", {}).get("review3", False),
                            on_change=on_change,
                            data={"daf": i, "amud": "a", "column": "review3"},
                        )
                    ),
                ]
                table.rows.append(ft.DataRow(cells=row_cells))

        # ... שאר הקוד של הפונקציה ...

        completion_icons[masechta_name] = ft.Icon(ft.icons.CIRCLE_OUTLINED)
        is_completed = update_masechta_completion_status(category, masechta_name)

        check_all_checkbox = ft.Checkbox(label="בחר הכל", on_change=check_all, value=is_completed)

        header = ft.Row(
            [
                ft.Text(masechta_name, size=20, weight=ft.FontWeight.BOLD),
                completion_icons[masechta_name],
                check_all_checkbox,
            ],
            alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        )

        return ft.Card(
            content=ft.Container(
                content=ft.Column(
                    [
                        header,
                        table,
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                ),
                padding=20,
            ),
        )

    def is_masechta_completed(category: str, masechta_name: str) -> bool:
        """
        פונקציה שבודקת האם מסכת/ספר הושלמו לגמרי.
        """
        progress = ProgressManager.load_progress(page, masechta_name, category)
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            return False

        total = get_total_pages(masechta_data)
        completed = get_completed_pages(progress, masechta_data["columns"])
        return completed == total

    def show_masechta(e):
        """
        עובר לנתיב של מסכת/ספר מסוים מתוך כפתור בחירה.
        """
        page.route = f"/masechta/{e.control.data['category']}/{e.control.data['masechta']}"
        page.update()

    def show_main_menu():
        nonlocal current_masechta
        current_masechta = None

        sections = {
            "תנ״ך": list(data.get("תנ״ך", {}).keys()),
            "תלמוד בבלי": list(data.get("תלמוד בבלי", {}).keys()),
            "תלמוד ירושלמי": list(data.get("תלמוד ירושלמי", {}).keys()),
            "רמב״ם": list(data.get("רמב״ם", {}).keys()),
            "שולחן ערוך": list(data.get("שולחן ערוך", {}).keys())
        }

        def create_masechta_button(masechta, category):
            return ft.ElevatedButton(
                text=masechta,
                data={"masechta": masechta, "category": category},
                on_click=show_masechta,
                style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=10), padding=15),
                width=150,
                height=50,
                icon=ft.icons.CHECK_CIRCLE if is_masechta_completed(category, masechta) else None,
                icon_color=ft.colors.GREEN if is_masechta_completed(category, masechta) else None,
            )

        return ft.Column(
            [
                ft.Text("בחר מקור:", size=24, weight=ft.FontWeight.BOLD,
                        text_align=ft.TextAlign.CENTER, style=ft.TextStyle(color=ft.colors.SECONDARY)),
                ft.Tabs(
                    selected_index=current_tab_index,
                    tabs=[
                        ft.Tab(
                            text=section_name,
                            content=ft.Container(
                                content=ft.GridView(
                                    controls=[
                                        create_masechta_button(masechta, section_name)
                                        for masechta in masechtot
                                    ] if masechtot else [],
                                    runs_count=3,
                                    max_extent=150,
                                    run_spacing=10,
                                    spacing=10,
                                    padding=10,
                                    visible=bool(masechtot),
                                ),
                                expand=True,
                            ),
                        )
                        for section_name, masechtot in sections.items()
                    ],
                    expand=1,
                ),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            expand=True,
        )

    def get_last_page_display(progress, masechta_data):
        """
        מחזיר מחרוזת המתארת את העמוד/פרק האחרון שנלמד.
        """
        if not progress:
            return "עדיין לא התחלת 😇"
        
        if masechta_data["content_type"] == "דף":
            # מוצאים את הדף האחרון שסימנו
            last_daf = max((daf for daf in progress.keys() if progress[daf].get("a", {}).get("learn", False) or progress[daf].get("b", {}).get("learn", False)), default=None)
            if last_daf:
                last_amud = "ב" if progress[last_daf].get("b", {}).get("learn", False) else "א"
                return f"{masechta_data['content_type']} {int_to_gematria(int(last_daf))} עמוד {last_amud}"
            else:
                return "עדיין לא התחלת 😇"
        else:
            # אם יש רק עמוד אחד לפרק
            last_chapter = max((daf for daf in progress.keys() if progress[daf].get("a", {}).get("learn", False)), default=None)
            if last_chapter:
                return f"{masechta_data['content_type']} {int_to_gematria(int(last_chapter))}"
            else:
                return "עדיין לא התחלת 😇"

    def create_tracking_page():
        """
        דף מעקב המציג ספרים בתהליך וספרים שהושלמו.
        """
        in_progress_items = []
        completed_items = []

        for category, masechtot in data.items():
            for masechta_name, masechta_data in masechtot.items():
                progress = ProgressManager.load_progress(page, masechta_name, category)
                if not progress:
                    continue  # לא נוצרה שום התקדמות

                total_pages = get_total_pages(masechta_data)
                completed_pages = get_completed_pages(progress, masechta_data["columns"])
                percentage = round((completed_pages / total_pages) * 100) if total_pages else 0

                # צבע טקסט בתוך bar לפי אחוזים
                text_color = ft.colors.WHITE if percentage >= 50 else ft.colors.BROWN_700

                # Stack עבור סרגל ההתקדמות
                progress_bar_with_text = ft.Stack(
                    [
                        ft.ProgressBar(value=percentage/100, height=25),
                        ft.Container(
                            content=ft.Text(f"{percentage}%", color=text_color, weight=ft.FontWeight.BOLD),
                            alignment=ft.alignment.center,
                            height=25,
                        )
                    ],
                    height=25,
                )

                if completed_pages < total_pages:
                    # ספר בתהליך
                    last_page_display = get_last_page_display(progress, masechta_data)
                    in_progress_items.append(
                        ft.Column(
                            [
                                ft.ElevatedButton(
                                    content=ft.Container(
                                        expand=True,
                                        content=ft.Column(
                                            [
                                                ft.Text(f"{masechta_name} ({category})", size=18, weight=ft.FontWeight.BOLD),
                                                progress_bar_with_text,
                                                ft.Text(f"אתה אוחז ב{last_page_display}"),
                                            ],
                                            spacing=5,
                                            alignment=ft.MainAxisAlignment.CENTER,
                                        ),
                                        padding=10,
                                    ),
                                    style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=10)),
                                    on_click=show_masechta,
                                    data={"masechta": masechta_name, "category": category},
                                    expand=True,
                                )
                            ],
                            col={"xs": 12, "sm": 6},
                            expand=True,
                        )
                    )
                else:
                    # ספר שהושלם
                    date_str = ProgressManager.get_completion_date(page, masechta_name, category)
                    hebrew_date_str = get_completion_date_string(date_str) if date_str else "לא ידוע"
                    completed_items.append(
                        ft.Column(
                            [
                                ft.ElevatedButton(
                                    content=ft.Container(
                                        expand=True,
                                        content=ft.Column(
                                            [
                                                ft.Text(f"{masechta_name} ({category})", size=18, weight=ft.FontWeight.BOLD),
                                                progress_bar_with_text,
                                                ft.Text(f"סיימת בתאריך {hebrew_date_str}"),
                                            ],
                                            spacing=10,
                                            alignment=ft.MainAxisAlignment.CENTER,
                                        ),
                                        padding=10,
                                    ),
                                    style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=10)),
                                    on_click=show_masechta,
                                    data={"masechta": masechta_name, "category": category},
                                    expand=True,
                                )
                            ],
                            col={"xs": 12, "sm": 6},
                            expand=True,
                        )
                    )

        # יצירת Rows רספונסיביים
        in_progress_responsive_row = ft.ResponsiveRow(
            controls=in_progress_items,
            alignment=ft.MainAxisAlignment.CENTER,
            visible=True
        )
        completed_responsive_row = ft.ResponsiveRow(
            controls=completed_items,
            alignment=ft.MainAxisAlignment.CENTER,
            visible=False
        )

        def on_segmented_button_change(e):
            if e.control.selected == {"in_progress"}:
                in_progress_responsive_row.visible = True
                completed_responsive_row.visible = False
            elif e.control.selected == {"completed"}:
                in_progress_responsive_row.visible = False
                completed_responsive_row.visible = True
            page.update()

        segmented_control = ft.SegmentedButton(
            selected={"in_progress"},
            allow_multiple_selection=False,
            on_change=on_segmented_button_change,
            segments=[
                ft.Segment(
                    value="in_progress",
                    label=ft.Text("בתהליך"),
                    icon=ft.Icon(ft.icons.HOURGLASS_EMPTY),
                ),
                ft.Segment(
                    value="completed",
                    label=ft.Text("סיימתי"),
                    icon=ft.Icon(ft.icons.CHECK_CIRCLE_OUTLINE),
                ),
            ],
        )

        return ft.Column(
            controls=[
                segmented_control,
                in_progress_responsive_row,
                completed_responsive_row,
            ],
            scroll="always",
            expand=True,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            visible=True,
        )

    def navigation_changed(e):
        nonlocal current_view
        if e.control.selected_index == 0:
            current_view = "tracking"
        else:
            current_view = "books"
        show_view()

    # AppBar ו-NavigationBar
    appbar = ft.AppBar(
        title=ft.Row(
            [
                ft.Icon(ft.icons.BOOK_OUTLINED),
                ft.Text("שמור וזכור", size=20, weight=ft.FontWeight.BOLD),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
        ),
        bgcolor=ft.colors.PRIMARY_CONTAINER,
        color=ft.colors.ON_PRIMARY_CONTAINER,
    )

    navigation_bar = ft.NavigationBar(
        destinations=[
            ft.NavigationDestination(icon=ft.icons.TIMELINE_OUTLINED, label="מעקב"),
            ft.NavigationDestination(icon=ft.icons.MENU_BOOK, label="ספרים"),
        ],
        selected_index=0,  # מעקב כברירת מחדל
        on_change=navigation_changed,
    )

    def handle_books_route():
        page.views.append(
            ft.View(
                "/books",
                [
                    appbar,
                    show_main_menu(),
                    navigation_bar,
                ],
            )
        )

    def handle_tracking_route():
        page.views.append(
            ft.View(
                "/tracking",
                [
                    appbar,
                    create_tracking_page(),
                    navigation_bar,
                ],
            )
        )

    def handle_masechta_route(category: str, masechta_name: str):
        nonlocal current_masechta, current_tab_index
        current_masechta = masechta_name

        # עדכון ה-Tabs לקטגוריה הנוכחית
        section_mapping = {
            "תנ״ך": 0,
            "תלמוד בבלי": 1,
            "תלמוד ירושלמי": 2,
            "רמב״ם": 3,
            "שולחן ערוך": 4
        }
        current_tab_index = section_mapping.get(category, 0)

        page.views.append(
            ft.View(
                f"/masechta/{category}/{masechta_name}",
                [
                    appbar,
                    create_table(category, current_masechta),
                    navigation_bar,
                ],
                scroll="always",
            )
        )

    def route_change(e):
        page.views.clear()
        route_parts = page.route.strip("/").split("/")

        if page.route in ["/", "/books"]:
            handle_books_route()
        elif page.route == "/tracking":
            handle_tracking_route()
        elif len(route_parts) == 3 and route_parts[0] == "masechta":
            category, masechta_name = route_parts[1], route_parts[2]
            handle_masechta_route(category, masechta_name)

        page.update()

    def show_view(view_name=None):
        if view_name:
            page.route = f"/{view_name}"
        else:
            page.route = f"/{current_view}"
        page.update()

    page.on_route_change = route_change
    show_view()

ft.app(target=main)