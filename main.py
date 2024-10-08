import flet as ft
from backend import save_progress, save_all_masechta, load_progress, load_data
from hebrew_numbers import int_to_gematria

def main(page: ft.Page):
    page.title = "שמור וזכור"
    page.rtl = True
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = ft.Theme(color_scheme_seed=ft.colors.BROWN)
    page.vertical_alignment = ft.MainAxisAlignment.START
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    page.padding = 20
    page.scroll = "adaptive"

    # טוען את כל הנתונים הרלוונטיים מקבצי ה-JSON השונים
    data = load_data()

    if not data:
        page.overlay.append(ft.SnackBar(ft.Text("Error loading data.")))  # שינוי ל-overlay.append
        page.update()
        return

    current_masechta = None
    completion_indicators = {}

    def update_completion_status(category, masechta_name):
        progress = load_progress(masechta_name)
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            return

        total_pages = 2 * masechta_data["pages"] if category == "תלמוד בבלי" else masechta_data["pages"]
        completed_pages = sum(1 for daf_data in progress.values() for amud_value in daf_data.values() if amud_value)

        complication = completed_pages == total_pages

        completion_indicators[masechta_name].icon = ft.icons.CHECK_CIRCLE if complication else ft.icons.CIRCLE_OUTLINED
        completion_indicators[masechta_name].color = ft.colors.GREEN if complication else ft.colors.GREY_400
        page.update()

        return complication

    def create_table(category, masechta_name):
        # גישה נכונה לקטגוריה ולמסכת בתוך הנתונים
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            page.overlay.append(ft.SnackBar(ft.Text(f"Error: Masechta '{masechta_name}' not found.")))
            page.update()
            return None

        progress = load_progress(masechta_name)

        def on_change(e):
            daf = int(e.control.data["daf"])
            amud = e.control.data["amud"]
            save_progress(masechta_name, daf, amud, e.control.value)
            update_completion_status(category, masechta_name)
            update_check_all_status(table)

        def check_all(e):
            for row in table.rows:
                if category == "תלמוד בבלי":
                    row.cells[1].content.value = e.control.value
                    row.cells[2].content.value = e.control.value
                else:
                    row.cells[1].content.value = e.control.value
            save_all_masechta(masechta_name, masechta_data["pages"], e.control.value)
            update_completion_status(category, masechta_name)

        def update_check_all_status(table):
            all_checked = all(row.cells[1].content.value for row in table.rows)
            check_all_checkbox.value = all_checked
            page.update()

        # הגדרת השמות המותאמים לכל נושא
        if category == "תלמוד בבלי":
            table_columns = [
                ft.DataColumn(ft.Text("דף")),
                ft.DataColumn(ft.Text("עמוד א")),
                ft.DataColumn(ft.Text("עמוד ב")),
            ]
        else:
            # שתי עמודות: מספר פרק/סימן + Checkbox לבדיקת סטטוס
            table_columns = [
                ft.DataColumn(ft.Text("פרק" if category == "תנ״ך" else "סימן")),
                ft.DataColumn(ft.Text("מצב"))
            ]

        table = ft.DataTable(
            columns=table_columns,
            rows=[],
            border=ft.border.all(1, "black"),
            column_spacing=30,
        )

        for i in range(1, masechta_data["pages"] + 1):
            daf_progress = progress.get(str(i), {})

            if category == "תלמוד בבלי":
                table.rows.append(
                    ft.DataRow(
                        cells=[
                            ft.DataCell(ft.Text(int_to_gematria(i))),
                            ft.DataCell(ft.Checkbox(value=daf_progress.get("a", False), on_change=on_change, data={"daf": i, "amud": "a"})),
                            ft.DataCell(ft.Checkbox(value=daf_progress.get("b", False), on_change=on_change, data={"daf": i, "amud": "b"})),
                        ],
                    )
                )
            else:
                # פרק/סימן + סטטוס (Checkbox)
                table.rows.append(
                    ft.DataRow(
                        cells=[
                            ft.DataCell(ft.Text(int_to_gematria(i))),
                            ft.DataCell(ft.Checkbox(value=daf_progress.get("a", False), on_change=on_change, data={"daf": i, "amud": "a"})),
                        ],
                    )
                )

        completion_indicators[masechta_name] = ft.Icon(ft.icons.CIRCLE_OUTLINED)

        complication = update_completion_status(category, masechta_name)

        check_all_checkbox = ft.Checkbox(label="בחר הכל", on_change=check_all, value=complication)

        header = ft.Row(
            [
                ft.Text(masechta_name, size=20, weight=ft.FontWeight.BOLD),
                completion_indicators[masechta_name],
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

    def show_masechta(e):
        nonlocal current_masechta
        current_masechta = e.control.data["masechta"]
        category = e.control.data["category"]
        page.views.clear()

        # יצירת הטבלה למסכת הנבחרת
        masechta_table = create_table(category, current_masechta)
        if masechta_table is None:
            return  # עצור את הביצוע אם יש שגיאה ביצירת הטבלה
        
        page.views.append(
            ft.View(
                "/masechta",
                [
                    ft.AppBar(title=ft.Text(current_masechta), leading=ft.IconButton(icon=ft.icons.ARROW_BACK, on_click=show_main_menu)),
                    masechta_table,
                ],
                vertical_alignment=ft.MainAxisAlignment.START,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                scroll="always",
            )
        )
        page.update()

    def show_main_menu(e=None):
        nonlocal current_masechta
        current_masechta = None

        sections = {
         "תנ״ך": list(data.get("תנ״ך", {}).keys()),
         "תלמוד בבלי": list(data.get("תלמוד בבלי", {}).keys()),
         "תלמוד ירושלמי": [],  # ניתן להוסיף בהמשך
         "רמב״ם": list(data.get("רמב״ם", {}).keys()),
         "שולחן ערוך": list(data.get("שולחן ערוך", {}).keys())
        }

        def create_masechta_button(masechta, category):
            completed = check_masechta_completion(category, masechta)
            return ft.ElevatedButton(
                text=masechta,
                data={"masechta": masechta, "category": category},
                on_click=show_masechta,
                style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=10), padding=15),
                width=150,
                height=50,
                icon=ft.icons.CHECK_CIRCLE if completed else None, 
                icon_color=ft.colors.GREEN if completed else None,
            )

        def check_masechta_completion(category, masechta_name):
            progress = load_progress(masechta_name)
            masechta_data = data[category].get(masechta_name)
            if not masechta_data:
                return False

            total_pages = 2 * masechta_data["pages"] if category == "תלמוד בבלי" else masechta_data["pages"]
            completed_pages = sum(1 for daf_data in progress.values() for amud_value in daf_data.values() if amud_value)
            return completed_pages == total_pages

        page.views.clear()
        page.views.append(
            ft.View(
                "/",
                [
                    ft.AppBar(
                        title=ft.Row(
                            [
                                ft.Icon(ft.icons.BOOK_OUTLINED),
                                ft.Text("שמור וזכור", size=20, weight=ft.FontWeight.BOLD),
                            ],
                            alignment=ft.MainAxisAlignment.CENTER,
                        ),
                        bgcolor=ft.colors.PRIMARY_CONTAINER,
                        color=ft.colors.ON_PRIMARY_CONTAINER,
                    ),
                    ft.Column(
                        [
                            ft.Text("בחר מקור:", size=24, weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER, style=ft.TextStyle(color=ft.colors.SECONDARY)),
                            ft.Tabs(
                                selected_index=1,
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
                    ),
                ],
            )
        )
        page.update()

    show_main_menu()

ft.app(target=main)
