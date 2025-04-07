import flet as ft
from flet import Page
from hebrew_numbers import int_to_gematria

from progress_manager import ProgressManager, get_completed_pages
from data_loader import load_data, get_total_pages, get_completion_date_string

def get_progress_value(item, key, default=False):
    """
    עוזר לקבל את ערך המפתח במידה והפריט הוא מילון,
    ואם הפריט הוא בוליאני – מחזיר אותו ישירות.
    """
    if isinstance(item, dict):
        return item.get(key, default)
    elif isinstance(item, bool):
        return item
    return default

def main(page: Page):
    page.title = "שמור וזכור"
    page.rtl = True
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = ft.Theme(color_scheme_seed=ft.Colors.BROWN)
    page.vertical_alignment = ft.MainAxisAlignment.START
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    page.padding = 20
    page.scroll = "adaptive"

    current_tab_index = 0
    current_view = "tracking"  # "tracking" או "books"

    data = load_data()  # נטען את הנתונים עם Cache
    if not data:
        page.overlay.append(ft.SnackBar(ft.Text("אופס! לא הצלחנו לטעון את הנתונים")))
        page.update()
        return

    completion_icons = {}
    current_masechta = None
    sections_book_buttons = {}  # Dictionary to store original book buttons
    search_results_tab = None # Store search results tab
    search_results_grid = None # Store the GridView for search results
    tabs_control = None # Store the Tabs control

    def update_masechta_completion_status(category: str, masechta_name: str):
        progress = ProgressManager.load_progress(page, masechta_name, category)
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            return False
        total_pages = get_total_pages(masechta_data)
        completed_pages = get_completed_pages(progress, masechta_data["columns"])
        is_completed = (completed_pages == total_pages)
        completion_icons[masechta_name].icon = ft.Icon(ft.Icons.CHECK_CIRCLE) if is_completed else ft.Icon(ft.Icons.CIRCLE_OUTLINED)
        completion_icons[masechta_name].color = ft.Colors.GREEN if is_completed else ft.Colors.GREY_400
        page.update()
        return is_completed

    def create_table(category: str, masechta_name: str):
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            page.overlay.append(ft.SnackBar(ft.Text(f"Error: Masechta '{masechta_name}' not found.")))
            page.update()
            return None

        progress = ProgressManager.load_progress(page, masechta_name, category)
        start_page = masechta_data.get("start_page", 1)
        is_daf_type = masechta_data["content_type"] == "דף" # בדוק אם זה ש"ס/ירושלמי

        def on_change(e):
            d = e.control.data
            ProgressManager.save_progress(
                page,
                masechta_name,
                d["daf"],
                d["amud"],
                d["column"],
                e.control.value,
                category,
            )
            update_masechta_completion_status(category, masechta_name)
            update_check_all_status()
            if is_masechta_completed(category, masechta_name):
                ProgressManager.save_completion_date(page, masechta_name, category)


        def check_all(e):
            # קבלת הערך החדש מה-Checkbox הראשי (True או False)
            new_value = e.control.value

            # חישוב הפרמטרים הנדרשים ל-save_all_masechta
            total_items_to_save = masechta_data["pages"]
            start_page_num = masechta_data.get("start_page", 1)
            is_daf = masechta_data["content_type"] == "דף"

            # שמירת המצב החדש באחסון (רק עמודת 'learn')
            ProgressManager.save_all_masechta(
                page, masechta_name, total_items_to_save, start_page_num, is_daf, new_value, category
            )

            # --- !!! התחלת התיקון !!! ---
            # רענון ידני של כל תיבות הסימון *בתצוגה* כדי לתת חיווי מיידי
            for row in table.rows:
                # תא 1 מכיל את ה-Container
                cell_content = row.cells[1].content
                # ודא שזה באמת Container
                if isinstance(cell_content, ft.Container):
                    # התוכן של ה-Container הוא ה-Row
                    checkbox_row = cell_content.content
                    # ודא שזה באמת Row ויש לו controls
                    if isinstance(checkbox_row, ft.Row) and hasattr(checkbox_row, 'controls'):
                        # עבור על כל הפקדים ב-Row
                        for control in checkbox_row.controls:
                            # אם הפקד הוא Checkbox, עדכן את הערך שלו
                            if isinstance(control, ft.Checkbox):
                                control.value = new_value
            # --- !!! סוף התיקון !!! ---

            # עדכן את אייקון ה-V הכללי של המסכת
            update_masechta_completion_status(category, masechta_name)

            # עדכן את התצוגה כולה
            page.update()



        def update_check_all_status():
            all_checked = True
            # נבדוק רק את תיבת הסימון של "learn" עבור כל יחידה (עמוד או פרק)
            for i in range(start_page, masechta_data["pages"] + start_page):
                daf_progress = progress.get(str(i), {})
                if is_daf_type:
                    if not get_progress_value(daf_progress.get("a", {}), "learn") or \
                       not get_progress_value(daf_progress.get("b", {}), "learn"):
                        all_checked = False
                        break
                else:
                    if not get_progress_value(daf_progress.get("a", {}), "learn"):
                        all_checked = False
                        break
                if not all_checked: # יציאה מוקדמת אם מצאנו אחד לא מסומן
                     break

            # אם לא כל תיבות ה'לימוד' מסומנות, נוריד את הסימון מ'בחר הכל'
            if not all_checked and check_all_checkbox.value:
                 check_all_checkbox.value = False
            # אם כל תיבות ה'לימוד' מסומנות, נסמן את 'בחר הכל'
            elif all_checked and not check_all_checkbox.value:
                 check_all_checkbox.value = True

            # אין צורך ב-page.update() כאן כי הוא נקרא בפונקציות האחרות

        table_columns = [
            ft.DataColumn(ft.Text(masechta_data["content_type"], weight=ft.FontWeight.BOLD)),
            ft.DataColumn(
                ft.Container( # עוטפים ב-Container כדי לשלוט ביישור
                    ft.Text("לימוד וחזרות", weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER),
                    alignment=ft.alignment.center, # ממקמים את הטקסט במרכז התא
                    expand=True, # מרחיבים את ה-Container למלוא רוחב העמודה
                )
            ),
        ]

        table = ft.DataTable(
            columns=table_columns,
            rows=[],
            column_spacing=20, # צמצום ריווח בין עמודות
            heading_row_height=45, # גובה שורת כותרת
            heading_row_color=ft.colors.with_opacity(0.1, ft.colors.PRIMARY), # צבע רקע עדין לכותרת
            # border=ft.border.all(1, ft.colors.OUTLINE_VARIANT), # גבול עדין סביב הטבלה
            border_radius=ft.border_radius.all(8), # פינות מעוגלות
            horizontal_lines=ft.border.BorderSide(1, ft.colors.with_opacity(0.2, ft.colors.OUTLINE)), # קווים אופקיים עדינים
            vertical_lines=ft.border.BorderSide(1, ft.colors.with_opacity(0.1, ft.colors.OUTLINE)), # קווים אנכיים עדינים
            data_row_max_height=55, # גובה מקסימלי לשורה (עוזר בריווח)
        )

        row_index = 0 # מונה לצביעה מתחלפת
        for i in range(start_page, masechta_data["pages"] + start_page):
            daf_progress = progress.get(str(i), {})
            amudim_to_process = ["a", "b"] if is_daf_type else ["a"]

            for amud_key in amudim_to_process:
                amud_progress = daf_progress.get(amud_key, {})
                is_amud_b = amud_key == "b"
                amud_symbol = ":" if is_amud_b else ("." if is_daf_type else "") # נקודה לעמוד א', נקודותיים לב', כלום לפרק/סימן

                row_label = f"{int_to_gematria(i)}{amud_symbol}"
                learn_val = get_progress_value(amud_progress, "learn")
                rev1_val = get_progress_value(amud_progress, "review1")
                rev2_val = get_progress_value(amud_progress, "review2")
                rev3_val = get_progress_value(amud_progress, "review3")

                # הגדרת צבע רקע מתחלף
                row_color = ft.colors.with_opacity(0.03, ft.colors.SECONDARY_CONTAINER) if row_index % 2 == 0 else None

                row_cells = [
                    ft.DataCell(ft.Text(row_label, font_family="Heebo")), # פונט קריא יותר למספרים עבריים
                    ft.DataCell(
                        # שימוש ב-Container כדי לשלוט ביישור ובריווח של תיבות הסימון
                        ft.Container(
                            content=ft.Row(
                                [
                                    ft.Checkbox(
                                        value=learn_val,
                                        on_change=on_change,
                                        data={"daf": i, "amud": amud_key, "column": "learn"},
                                        tooltip="לימוד",
                                    ),
                                    ft.Checkbox(
                                        value=rev1_val,
                                        on_change=on_change,
                                        data={"daf": i, "amud": amud_key, "column": "review1"},
                                        tooltip="חזרה 1",
                                    ),
                                    ft.Checkbox(
                                        value=rev2_val,
                                        on_change=on_change,
                                        data={"daf": i, "amud": amud_key, "column": "review2"},
                                        tooltip="חזרה 2",
                                    ),
                                    ft.Checkbox(
                                        value=rev3_val,
                                        on_change=on_change,
                                        data={"daf": i, "amud": amud_key, "column": "review3"},
                                        tooltip="חזרה 3",
                                    )
                                ],
                                # יישור למרכז התא וריווח שווה בין התיבות
                                alignment=ft.MainAxisAlignment.SPACE_EVENLY,
                                vertical_alignment=ft.CrossAxisAlignment.CENTER,
                                spacing=5, # ריווח קטן בין התיבות
                                tight=True, # מנסה לצופף את השורה
                            ),
                            alignment=ft.alignment.center, # ממורכז בתוך התא
                            padding=ft.padding.symmetric(vertical=0, horizontal=5), # ריווח פנימי קטן
                        )
                    ),
                ]
                table.rows.append(ft.DataRow(cells=row_cells, color=row_color))
                row_index += 1 # קדם את המונה לצבע הבא

        completion_icons[masechta_name] = ft.Icon(ft.Icons.CIRCLE_OUTLINED) # אתחול אייקון
        is_completed = update_masechta_completion_status(category, masechta_name) # עדכון ראשוני
        check_all_checkbox = ft.Checkbox(label="סמן הכל כנלמד", on_change=check_all, value=is_completed)
        update_check_all_status() # קריאה נוספת לעדכון ה-checkbox לפי המצב המדויק

        header = ft.Row(
            [
                ft.Text(masechta_name, size=24, weight=ft.FontWeight.BOLD), # הגדלת כותרת המסכת
                completion_icons[masechta_name],
                check_all_checkbox,
            ],
            alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        )

        # עטיפת הטבלה ב-Container וב-Column כדי לאפשר גלילה אנכית במידת הצורך
        table_container = ft.Container(
            content=ft.Column(
                [table],
                scroll=ft.ScrollMode.ADAPTIVE, # מאפשר גלילה אנכית לטבלה אם היא ארוכה מדי
                expand=False, # לא מרחיבים את ה-Column, נותנים ל-Card לנהל גודל
                # horizontal_alignment=ft.CrossAxisAlignment.STRETCH, # מותח את הטבלה לרוחב
                ),
            padding=ft.padding.only(top=10) # ריווח מעל הטבלה
        )


        return ft.Card(
            elevation=2, # הצללה קלה לכרטיס
            content=ft.Container(
                content=ft.Column(
                    [
                        header,
                        ft.Divider(height=1, color=ft.colors.with_opacity(0.5, ft.colors.OUTLINE)), # קו מפריד
                        table_container, # הטבלה העטופה
                    ],
                    spacing=10, # ריווח בין הכותרת, הקו והטבלה
                    # horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    tight=True, # מנסה לצופף את התוכן ב-Column
                ),
                padding=15, # ריווח פנימי לכרטיס
                border_radius=ft.border_radius.all(10), # פינות מעוגלות לתוכן הכרטיס
            ),
        )


    def is_masechta_completed(category: str, masechta_name: str) -> bool:
        progress = ProgressManager.load_progress(page, masechta_name, category)
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            return False
        total = get_total_pages(masechta_data)
        completed = get_completed_pages(progress, masechta_data["columns"])
        return completed == total

    def show_masechta(e):
        page.route = f"/masechta/{e.control.data['category']}/{e.control.data['masechta']}"
        page.update()

    def show_main_menu():
        nonlocal current_masechta, sections_book_buttons, search_results_tab, search_results_grid, tabs_control
        current_masechta = None

        sections = {
            "תנ״ך": list(data.get("תנ״ך", {}).keys()),
            "תלמוד בבלי": list(data.get("תלמוד בבלי", {}).keys()),
            "תלמוד ירושלמי": list(data.get("תלמוד ירושלמי", {}).keys()),
            "רמב״ם": list(data.get("רמב״ם", {}).keys()),
            "שולחן ערוך": list(data.get("שולחן ערוך", {}).keys())
        }

        def create_masechta_button(masechta, category, visible=True, include_category=False):
            if include_category:
                # Use a Column to display name and category on separate lines
                content = ft.Column(
                    [
                        ft.Text(masechta, size=16),  # Regular size
                        ft.Text(category, size=13),
                    ],
                    tight=True,  # Reduce spacing between lines
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER, # Center-align text
                )
            else:
                content = ft.Text(masechta, size=16)  # Regular button content

            return ft.ElevatedButton(
                content=content, # Use content instead of text
                data={"masechta": masechta, "category": category},
                on_click=show_masechta,
                style=ft.ButtonStyle(
                    shape=ft.RoundedRectangleBorder(radius=10),
                    padding=15,
                ),
                width=150,
                height=70, # Adjust as needed, allow more height.
                icon=ft.Icon(ft.Icons.CHECK_CIRCLE) if is_masechta_completed(category, masechta) else None,
                icon_color=ft.Colors.GREEN if is_masechta_completed(category, masechta) else None,
                visible=visible,
            )


        def perform_search(search_term):
            results = []
            for category, masechtot in data.items():
                for masechta_name in masechtot:
                    if search_term.lower() in masechta_name.lower():
                        results.append(create_masechta_button(masechta_name, category, include_category=True)) # Pass include_category=True
            return results

        def search_changed(e):
            nonlocal search_results_grid, search_results_tab, tabs_control
            search_term = e.control.value

            if len(search_term) >= 2: # Only search if 2 or more characters
                search_results = perform_search(search_term)

                if search_results_grid is None: # First time creating it
                  search_results_grid = ft.GridView(
                        controls=search_results,
                        runs_count=3,
                        max_extent=150,
                        run_spacing=10,
                        spacing=10,
                        padding=10,
                    )
                  search_results_tab.content = ft.Container(content=search_results_grid, expand=True)
                else:
                    search_results_grid.controls = search_results # Update existing grid

                # Show/hide and select the search results tab
                if search_term and page.route == "/books":  # Only if there's a search term AND we are on /books
                    search_results_tab.tab_content.visible = True
                    if search_results:
                        tabs_control.selected_index = len(tabs_control.tabs) - 1 # Select search results tab
                elif page.route == "/books":  # If no search term, and we are on /books, hide the tab
                    search_results_tab.tab_content.visible = False
            elif page.route == "/books": # Less than 2 characters, and on /books, so hide
                search_results_tab.tab_content.visible = False
                if search_results_grid: # Clear previous search results
                    search_results_grid.controls = []


            page.update()



        search_tf = ft.TextField(
            hint_text="חיפוש ספר...",
            prefix_icon=ft.Icons.SEARCH,
            on_change=search_changed,
            width=400,  # Increased width slightly
            border_radius=30,  # More rounded corners
            border_color=ft.colors.PRIMARY,  # Use the primary color for the border
            bgcolor=ft.colors.SECONDARY_CONTAINER, # A subtle background
            filled=True, # Fill the background
            dense=True,   # Make it more compact
            content_padding=12, # Adjust padding for visual balance
        )

        # Moved tab creation *OUTSIDE* the loop.  Create ONCE.
        tab_list = []
        for section_name, masechtot in sections.items():
            book_buttons = [create_masechta_button(masechta, section_name) for masechta in masechtot]
            sections_book_buttons[section_name] = book_buttons

            tab_content = ft.Container(
                content=ft.GridView(
                    controls=book_buttons,
                    runs_count=3,
                    max_extent=150,
                    run_spacing=10,
                    spacing=10,
                    padding=10,
                ),
                expand=True,
            )
            tab_list.append(ft.Tab(text=section_name, content=tab_content))

        # "Search Results" tab with only the search icon - created *ONCE*
        if search_results_tab is None:  # Create only if it doesn't exist
            search_results_tab = ft.Tab(
                tab_content=ft.Icon(ft.Icons.SEARCH),  # Only the icon
                content=ft.Container(), # Empty container, will be filled later
            )
            search_results_tab.tab_content.visible = False # Initially hidden

        tab_list.append(search_results_tab)  # Append to the *END*


        tabs_control = ft.Tabs(
            selected_index=current_tab_index,  # Use stored index
            tabs=tab_list,
            expand=1,
        )

        return ft.Column(
            [
                ft.Container(search_tf, padding=ft.padding.only(bottom=10)),
                tabs_control,
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            expand=True,
        )

    def get_last_page_display(progress, masechta_data):
        if not progress:
            return "עדיין לא התחלת"

        # סינון ראשוני של מפתחות שהם מספרים ושיש להם ערך 'learn' כלשהו
        valid_keys = [
            key for key in progress.keys()
            if key.isdigit() and (
                get_progress_value(progress[key].get("a", {}), "learn") or
                (masechta_data["content_type"] == "דף" and get_progress_value(progress[key].get("b", {}), "learn"))
            )
        ]

        if not valid_keys:
            return "עדיין לא התחלת"

        # --- תיקון: המרת המפתחות למספרים לפני מציאת המקסימום ---
        last_page_num = max(int(key) for key in valid_keys)
        # ---------------------------------------------------------

        last_page_str = str(last_page_num) # נמיר חזרה למחרוזת לשימוש כמפתח במילון

        if masechta_data["content_type"] == "דף":
            # הבדיקה אם עמוד ב' סומן צריכה להשתמש ב-last_page_str
            last_amud = "ב" if get_progress_value(progress[last_page_str].get("b", {}), "learn") else "א"
            # ההמרה לגימטריה צריכה להשתמש ב-last_page_num
            return f"{masechta_data['content_type']} {int_to_gematria(last_page_num)} עמוד {last_amud}"
        else: # פרק או סימן
            # ההמרה לגימטריה צריכה להשתמש ב-last_page_num
            return f"{masechta_data['content_type']} {int_to_gematria(last_page_num)}"

    def create_tracking_page():
        in_progress_items = []
        completed_items = []

        for category, masechtot in data.items():
            for masechta_name, masechta_data in masechtot.items():
                progress = ProgressManager.load_progress(page, masechta_name, category)
                if not progress:
                    continue

                total_pages = get_total_pages(masechta_data)
                completed_pages = get_completed_pages(progress, masechta_data["columns"])
                percentage = round((completed_pages / total_pages) * 100) if total_pages else 0

                text_color = ft.Colors.WHITE if percentage >= 50 else ft.Colors.BROWN_700

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
                                                ft.Text(f"הגעת ל{last_page_display}"),
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
                    icon=ft.Icon(ft.Icons.HOURGLASS_EMPTY),
                ),
                ft.Segment(
                    value="completed",
                    label=ft.Text("סיימתי"),
                    icon=ft.Icon(ft.Icons.CHECK_CIRCLE_OUTLINE),
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

    appbar = ft.AppBar(
        title=ft.Row(
            [
                ft.Icon(ft.Icons.BOOK_OUTLINED),
                ft.Text("שמור וזכור", size=20, weight=ft.FontWeight.BOLD),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
        ),
        bgcolor=ft.Colors.PRIMARY_CONTAINER,
        color=ft.Colors.ON_PRIMARY_CONTAINER,
    )

    navigation_bar = ft.NavigationBar(
        destinations=[
            ft.NavigationBarDestination(icon=ft.Icon(ft.Icons.TIMELINE_OUTLINED), label="מעקב"),
            ft.NavigationBarDestination(icon=ft.Icon(ft.Icons.MENU_BOOK), label="ספרים"),
        ],
        selected_index=0,
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
        nonlocal search_results_tab, search_results_grid, current_tab_index, tabs_control
        page.views.clear()
        route_parts = page.route.strip("/").split("/")


        if page.route in ["/", "/books"]:
            handle_books_route()
            # Reset search and select first tab ONLY when going to /books (or /)
            if search_results_tab:
                search_results_tab.tab_content.visible = False  # Hide search results
            if search_results_grid:
                search_results_grid.controls = []  # Clear previous results
            current_tab_index = 0          # Reset selected tab index
            if tabs_control:
              tabs_control.selected_index = current_tab_index



        elif page.route == "/tracking":
            handle_tracking_route()
        elif len(route_parts) == 3 and route_parts[0] == "masechta":
            category, masechta_name = route_parts[1], route_parts[2]
            handle_masechta_route(category, masechta_name)
        # Hide search results tab content on route change, *except* when returning to /books.
        if search_results_tab and page.route != "/books":
            search_results_tab.tab_content.visible = False

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