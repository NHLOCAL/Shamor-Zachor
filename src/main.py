import flet as ft
from flet import Page
from hebrew_numbers import int_to_gematria

from progress_manager import ProgressManager, get_completed_pages
from data_loader import load_data, get_total_pages, get_completion_date_string

# --- get_progress_value function (no changes) ---
def get_progress_value(item, key, default=False):
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
    page.scroll = "adaptive" # Keep page-level scroll for base views

    # --- State Variables ---
    current_tab_index = 0
    data = load_data()
    if not data:
        page.overlay.append(ft.SnackBar(ft.Text("אופס! לא הצלחנו לטעון את הנתונים")))
        page.update()
        return

    completion_icons = {}
    current_masechta = None
    sections_book_buttons = {}
    search_results_tab = None
    search_results_grid = None
    tabs_control = None
    navigation_bar = None
    search_tf = None # Define search_tf here to access its value later
    search_tab_label = None # Define search_tab_label here

    # --- Global Controls ---
    appbar = ft.AppBar(
        title=ft.Row(
            [
                ft.Icon(ft.Icons.BOOK_OUTLINED),
                ft.Text("שמור וזכור", size=20, weight=ft.FontWeight.BOLD),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
        ),
        center_title=True,
        bgcolor=ft.Colors.PRIMARY_CONTAINER,
        color=ft.Colors.ON_PRIMARY_CONTAINER,
        # --- הוספת השורה הזו ---
        automatically_imply_leading=False
        # -------------------------
    )


    navigation_bar = ft.NavigationBar(
        destinations=[
            ft.NavigationBarDestination(icon=ft.Icon(ft.Icons.TIMELINE_OUTLINED), label="מעקב"),
            ft.NavigationBarDestination(icon=ft.Icon(ft.Icons.MENU_BOOK), label="ספרים"),
        ],
        selected_index=0,
        on_change=lambda e: navigation_changed(e),
    )
    # --- End Global Controls ---

    def go_back(e):
        """Navigates back by removing the top view."""
        if len(page.views) > 1:
            page.views.pop()
            top_view = page.views[-1]
            if top_view.route == "/tracking":
                navigation_bar.selected_index = 0
            elif top_view.route == "/books":
                navigation_bar.selected_index = 1
            page.go(top_view.route)

    # --- update_masechta_completion_status (no changes needed from previous correct version) ---
    def update_masechta_completion_status(category: str, masechta_name: str):
        progress = ProgressManager.load_progress(page, masechta_name, category)
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            return False
        total_pages = get_total_pages(masechta_data)
        completed_pages = get_completed_pages(progress, ["learn"]) # Check only 'learn'
        is_completed = (completed_pages >= total_pages and total_pages > 0) # Ensure total_pages > 0

        icon_widget = completion_icons.get(masechta_name)
        if icon_widget: # Check if icon exists before updating
            icon_widget.icon = ft.Icon(ft.Icons.CHECK_CIRCLE) if is_completed else ft.Icon(ft.Icons.CIRCLE_OUTLINED)
            icon_widget.color = ft.Colors.GREEN if is_completed else ft.Colors.GREY_400
        return is_completed

    # --- create_table (no changes needed from previous correct version with back button) ---
    def create_table(category: str, masechta_name: str):
        masechta_data = data[category].get(masechta_name)
        if not masechta_data:
            return ft.Text(f"Error: Masechta '{masechta_name}' not found in category '{category}'.")

        progress = ProgressManager.load_progress(page, masechta_name, category)
        start_page = masechta_data.get("start_page", 1)
        is_daf_type = masechta_data["content_type"] == "דף"

        all_checkboxes_in_view = []
        learn_checkboxes_in_view = []

        def is_masechta_completed(cat: str, masechta: str) -> bool:
            # Helper defined inside or globally
            _progress = ProgressManager.load_progress(page, masechta, cat)
            _masechta_data = data[cat].get(masechta)
            if not _masechta_data: return False
            _total = get_total_pages(_masechta_data)
            if _total == 0: return False
            _completed = get_completed_pages(_progress, ["learn"])
            return _completed >= _total

        def on_change(e):
            nonlocal progress
            d = e.control.data
            ProgressManager.save_progress(
                page, masechta_name, d["daf"], d["amud"], d["column"], e.control.value, category,
            )
            progress = ProgressManager.load_progress(page, masechta_name, category) # Reload

            update_masechta_completion_status(category, masechta_name)
            update_check_all_status() # Update based on reloaded progress

            is_now_complete = is_masechta_completed(category, masechta_name)
            if is_now_complete and not ProgressManager.get_completion_date(page, masechta_name, category):
                 ProgressManager.save_completion_date(page, masechta_name, category)
            # Consider removing date if unchecking makes it incomplete (optional)
            # elif not is_now_complete and d["column"] == "learn" and ProgressManager.get_completion_date(page, masechta_name, category):
            #     ProgressManager.remove_completion_date(page, masechta_name, category) # Assuming remove_completion_date exists

            page.update()

        def update_check_all_status():
            is_complete = is_masechta_completed(category, masechta_name)
            if check_all_checkbox.value != is_complete:
                 check_all_checkbox.value = is_complete

        def check_all(e):
            new_value = e.control.value
            total_items_to_save = masechta_data["pages"]
            start_page_num = masechta_data.get("start_page", 1)
            is_daf = masechta_data["content_type"] == "דף"

            ProgressManager.save_all_masechta(
                page, masechta_name, total_items_to_save, start_page_num, is_daf, new_value, category
            )

            # Update checkboxes visually
            for cb in learn_checkboxes_in_view:
                 if cb.value != new_value: cb.value = new_value
            if not new_value: # Uncheck reviews if unchecking all
                for cb in all_checkboxes_in_view:
                     if cb.data["column"] != "learn" and cb.value: cb.value = False

            nonlocal progress
            progress = ProgressManager.load_progress(page, masechta_name, category) # Reload

            update_masechta_completion_status(category, masechta_name)
            update_check_all_status()
            page.update()

        # --- Build Header Row (no changes) ---
        header_row = ft.ResponsiveRow(
            [
                ft.Container(ft.Text(masechta_data["content_type"], weight=ft.FontWeight.BOLD), padding=ft.padding.symmetric(vertical=10, horizontal=8), alignment=ft.alignment.center_right, col={"xs": 3, "sm": 2, "md": 2, "lg": 1}),
                ft.Container(ft.Text("לימוד וחזרות", weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER), padding=ft.padding.symmetric(vertical=10, horizontal=8), alignment=ft.alignment.center, col={"xs": 9, "sm": 10, "md": 10, "lg": 11}),
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, vertical_alignment=ft.CrossAxisAlignment.CENTER
        )

        # --- Build Data Rows (no changes) ---
        list_items = []
        row_index = 0
        # (Loop to create checkboxes and rows as before)
        for i in range(start_page, masechta_data["pages"] + start_page):
            daf_str = str(i)
            daf_progress = progress.get(daf_str, {})
            amudim_to_process = ["a", "b"] if is_daf_type else ["a"]
            for amud_key in amudim_to_process:
                amud_progress = daf_progress.get(amud_key, {})
                is_amud_b = amud_key == "b"
                amud_symbol = ":" if is_amud_b else ("." if is_daf_type else "")
                row_label = f"{int_to_gematria(i)}{amud_symbol}"

                learn_cb = ft.Checkbox(value=get_progress_value(amud_progress, "learn"), on_change=on_change, data={"daf": i, "amud": amud_key, "column": "learn"}, tooltip="לימוד")
                review1_cb = ft.Checkbox(value=get_progress_value(amud_progress, "review1"), on_change=on_change, data={"daf": i, "amud": amud_key, "column": "review1"}, tooltip="חזרה 1")
                review2_cb = ft.Checkbox(value=get_progress_value(amud_progress, "review2"), on_change=on_change, data={"daf": i, "amud": amud_key, "column": "review2"}, tooltip="חזרה 2")
                review3_cb = ft.Checkbox(value=get_progress_value(amud_progress, "review3"), on_change=on_change, data={"daf": i, "amud": amud_key, "column": "review3"}, tooltip="חזרה 3")

                all_checkboxes_in_view.extend([learn_cb, review1_cb, review2_cb, review3_cb])
                learn_checkboxes_in_view.append(learn_cb)

                row_bgcolor = ft.colors.with_opacity(0.03, ft.colors.SECONDARY_CONTAINER) if row_index % 2 == 0 else None
                data_responsive_row = ft.ResponsiveRow(
                    [
                        ft.Container(content=ft.Text(row_label, font_family="Heebo"), padding=ft.padding.symmetric(vertical=12, horizontal=8), alignment=ft.alignment.center_right, col={"xs": 3, "sm": 2, "md": 2, "lg": 1}),
                        ft.Container(content=ft.Row([learn_cb, review1_cb, review2_cb, review3_cb], alignment=ft.MainAxisAlignment.SPACE_EVENLY, vertical_alignment=ft.CrossAxisAlignment.CENTER, spacing=2, wrap=False, tight=True), padding=ft.padding.symmetric(vertical=0, horizontal=5), alignment=ft.alignment.center, col={"xs": 9, "sm": 10, "md": 10, "lg": 11}),
                    ], vertical_alignment=ft.CrossAxisAlignment.CENTER, run_spacing=0
                )
                list_items.append(ft.Container(content=data_responsive_row, bgcolor=row_bgcolor, border_radius=ft.border_radius.all(4)))
                list_items.append(ft.Divider(height=1, thickness=0.5, color=ft.colors.with_opacity(0.15, ft.colors.OUTLINE)))
                row_index += 1

        # --- Final Assembly ---
        completion_icons[masechta_name] = ft.Icon(ft.Icons.CIRCLE_OUTLINED)
        is_completed_initially = is_masechta_completed(category, masechta_name)
        update_masechta_completion_status(category, masechta_name)

        check_all_checkbox = ft.Checkbox(
            label="סמן הכל כנלמד",
            on_change=check_all,
            value=is_completed_initially
        )

        # --- Main Header (with Back Button) ---
        main_header = ft.Row(
            [
                ft.IconButton(ft.icons.ARROW_FORWARD, tooltip="חזור", on_click=go_back),
                ft.Text(masechta_name, size=24, weight=ft.FontWeight.BOLD, expand=True, text_align=ft.TextAlign.CENTER),
                completion_icons[masechta_name],
                check_all_checkbox,
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, vertical_alignment=ft.CrossAxisAlignment.CENTER
        )

        # --- Content Column (Scrollable) ---
        content_column = ft.Column(
            [
                header_row,
                ft.Divider(height=1, color=ft.colors.with_opacity(0.5, ft.colors.OUTLINE)),
                *list_items
            ],
            scroll=ft.ScrollMode.ADAPTIVE, # Internal scroll for the list
            expand=True, # Takes available space within the card
            spacing=0,
        )

        return ft.Card(
            elevation=2,
            content=ft.Container(
                content=ft.Column(
                    [
                        main_header,
                        ft.Divider(height=5, color=ft.colors.TRANSPARENT),
                        content_column, # The scrollable list part
                    ],
                    spacing=5,
                    tight=True,
                ),
                padding=15,
                border_radius=ft.border_radius.all(10),
            ),
        )
    # --- End create_table ---

    # --- is_masechta_completed (Global helper, same as inner one) ---
    def is_masechta_completed(category: str, masechta_name: str) -> bool:
        _progress = ProgressManager.load_progress(page, masechta_name, category)
        _masechta_data = data[category].get(masechta_name)
        if not _masechta_data: return False
        _total = get_total_pages(_masechta_data)
        if _total == 0: return False
        _completed = get_completed_pages(_progress, ["learn"])
        return _completed >= _total

    # --- show_masechta (no changes) ---
    def show_masechta(e):
        page.go(f"/masechta/{e.control.data['category']}/{e.control.data['masechta']}")

    # --- show_main_menu (SEARCH FIXES) ---
    def show_main_menu():
        nonlocal sections_book_buttons, search_results_tab, search_results_grid, tabs_control, current_tab_index, search_tf, search_tab_label

        sections = {
            "תנ״ך": list(data.get("תנ״ך", {}).keys()),
            "תלמוד בבלי": list(data.get("תלמוד בבלי", {}).keys()),
            "תלמוד ירושלמי": list(data.get("תלמוד ירושלמי", {}).keys()),
            "רמב״ם": list(data.get("רמב״ם", {}).keys()),
            "שולחן ערוך": list(data.get("שולחן ערוך", {}).keys())
        }

        # --- create_masechta_button (no changes) ---
        def create_masechta_button(masechta, category, visible=True, include_category=False):
            is_complete = is_masechta_completed(category, masechta)
            button_content = None # Initialize content variable

            # Define the check icon here for reuse
            check_icon = ft.Icon(ft.icons.CHECK_CIRCLE, color=ft.colors.GREEN, size=18)

            if include_category: # Search results style
                masechta_text_widget = ft.Text(masechta, size=16)
                category_text_widget = ft.Text(category, size=13, color=ft.colors.GREY_600) # Corrected color

                # Create the display for the first line (Masechta name + optional icon)
                if is_complete:
                    # Combine icon and masechta name in a Row
                    masechta_display = ft.Row(
                        [
                            check_icon, # Use the defined icon
                            masechta_text_widget,
                        ],
                        alignment=ft.MainAxisAlignment.CENTER, # Center the row content
                        vertical_alignment=ft.CrossAxisAlignment.CENTER,
                        spacing=4, # Adjust spacing between icon and text
                        tight=True
                    )
                else:
                    # Just the masechta name centered (use a Row for consistent centering)
                    masechta_display = ft.Row(
                        [masechta_text_widget],
                         alignment=ft.MainAxisAlignment.CENTER
                    )


                # Build the final column content for the button
                button_content = ft.Column(
                    [
                        masechta_display, # The Row (with or without icon) or just Text
                        category_text_widget
                    ],
                    tight=True,
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=2 # Spacing between the two lines
                )
                height = 75 # Height for two lines

            else: # Standard book tab style
                masechta_text_widget = ft.Text(masechta, size=16, text_align=ft.TextAlign.CENTER) # Center text

                if is_complete:
                    # Use a Row to combine icon and text
                    button_content = ft.Row(
                        [
                            check_icon, # Use the defined icon
                            masechta_text_widget,
                        ],
                        alignment=ft.MainAxisAlignment.CENTER, # Center the row content
                        vertical_alignment=ft.CrossAxisAlignment.CENTER,
                        spacing=4, # Adjust spacing
                        tight=True
                    )
                else:
                    # Just the text widget is enough if centered
                    button_content = masechta_text_widget

                height = 65 # Standard height for one line (or row)

            # Create the ElevatedButton using the constructed 'button_content'
            # REMOVE the top-level 'icon' and 'icon_color' parameters
            return ft.ElevatedButton(
                content=button_content, # Use the constructed content (Row, Column, or Text)
                data={"masechta": masechta, "category": category},
                on_click=show_masechta,
                style=ft.ButtonStyle(
                    shape=ft.RoundedRectangleBorder(radius=10),
                    # Padding might need slight adjustment if content structure changed
                    padding=ft.padding.symmetric(horizontal=8, vertical=5),
                ),
                tooltip=f"פתח את {masechta}",
                width=150,
                height=height,
                # icon=... REMOVED
                # icon_color=... REMOVED
                visible=visible
            )

        # --- perform_search (no changes) ---
        def perform_search(search_term):
            results = []
            search_term_lower = search_term.lower()
            for category, masechtot in data.items():
                for masechta_name in masechtot:
                    if search_term_lower in masechta_name.lower():
                        results.append(create_masechta_button(masechta_name, category, include_category=True))
            return results

        # --- search_changed (REVISED LOGIC) ---
        def search_changed(e):
            nonlocal search_results_grid, search_results_tab, tabs_control, search_tab_label
            search_term = e.control.value.strip()

            # Ensure controls exist
            if not all([search_results_grid, search_results_tab, tabs_control, search_tab_label]):
                print("Warning: Search controls not fully initialized.")
                return

            search_tab_index = len(tabs_control.tabs) - 1

            if len(search_term) >= 2:
                search_results = perform_search(search_term)
                search_results_grid.controls = search_results

                if search_results:
                    # Show label and select tab only if there are results
                    search_tab_label.visible = True
                    # Select the tab only if it's not already selected
                    if tabs_control.selected_index != search_tab_index:
                         tabs_control.selected_index = search_tab_index
                else:
                    # No results found, hide label
                    search_tab_label.visible = False
                    # If search tab is selected, switch back to previous category tab
                    if tabs_control.selected_index == search_tab_index:
                        tabs_control.selected_index = current_tab_index

            else: # Less than 2 characters
                 search_results_grid.controls = [] # Clear grid
                 search_tab_label.visible = False # Hide label
                 # If search tab is selected, switch back
                 if tabs_control.selected_index == search_tab_index:
                     tabs_control.selected_index = current_tab_index

            page.update()
        # --- End search_changed ---

        def on_tab_change(e):
            nonlocal current_tab_index
            selected_index = e.control.selected_index
            search_tab_index = len(tabs_control.tabs) - 1
            # Only store index if it's not the search tab
            if selected_index != search_tab_index:
                current_tab_index = selected_index
                # Maybe hide search label if user clicks away? Optional.
                # if search_tab_label: search_tab_label.visible = False

        # --- Create Search TextField (ensure it's assigned to nonlocal search_tf) ---
        if search_tf is None: # Create only once
            search_tf = ft.TextField(
                hint_text="חיפוש ספר...",
                prefix_icon=ft.Icons.SEARCH,
                on_change=search_changed, # Connect the revised function
                width=400,
                border_radius=30,
                border_color=ft.colors.PRIMARY,
                bgcolor=ft.colors.with_opacity(0.05, ft.colors.SECONDARY_CONTAINER),
                filled=True,
                dense=True,
                content_padding=12,
            )

        # --- Create Tabs (ensure controls are assigned to nonlocals) ---
        if tabs_control is None:
            tab_list = []
            for section_name, masechtot in sections.items():
                book_buttons = [create_masechta_button(masechta, section_name) for masechta in masechtot]
                tab_content = ft.Container(content=ft.GridView(controls=book_buttons, runs_count=3, max_extent=160, run_spacing=10, spacing=10, padding=10), expand=True)
                tab_list.append(ft.Tab(text=section_name, content=tab_content))

            # Create search grid and label (assign to nonlocals)
            search_results_grid = ft.GridView(controls=[], runs_count=3, max_extent=160, run_spacing=10, spacing=10, padding=10)
            search_tab_label = ft.Row([ft.Icon(ft.Icons.SEARCH), ft.Text("חיפוש")], tight=True, spacing=5, visible=False) # Start hidden
            search_results_tab = ft.Tab(tab_content=search_tab_label, content=ft.Container(content=search_results_grid, expand=True))
            tab_list.append(search_results_tab)

            tabs_control = ft.Tabs(selected_index=current_tab_index, tabs=tab_list, expand=1, on_change=on_tab_change)
        else:
            # Refresh book buttons in existing tabs
            for i, section_name in enumerate(sections.keys()):
                 book_buttons = [create_masechta_button(masechta, section_name) for masechta in sections[section_name]]
                 try:
                     grid_view = tabs_control.tabs[i].content.content
                     if isinstance(grid_view, ft.GridView): grid_view.controls = book_buttons
                 except AttributeError: pass # Ignore if structure changed

            # Ensure correct tab is selected and search label visibility is correct
            tabs_control.selected_index = current_tab_index
            current_search_term = search_tf.value if search_tf else ""
            # Hide search label if search term is short or grid is empty
            search_tab_label.visible = (len(current_search_term) >= 2 and search_results_grid and search_results_grid.controls)

        return ft.Column(
            [
                ft.Container(search_tf, padding=ft.padding.only(bottom=10)),
                tabs_control,
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            expand=True,
        )
    # --- End show_main_menu ---

    # --- get_last_page_display (no changes needed) ---
    def get_last_page_display(progress, masechta_data):
        if not progress: return "עדיין לא התחלת"
        valid_keys = [key for key in progress.keys() if key.isdigit() and (get_progress_value(progress[key].get("a", {}), "learn") or (masechta_data.get("content_type") == "דף" and get_progress_value(progress[key].get("b", {}), "learn")))]
        if not valid_keys: return "עדיין לא התחלת"
        try: last_page_num = max(int(key) for key in valid_keys)
        except ValueError: return "שגיאה בנתונים"
        last_page_str = str(last_page_num)
        content_type = masechta_data.get("content_type", "עמוד")
        if content_type == "דף":
            last_amud = ""
            page_prog = progress.get(last_page_str, {})
            if get_progress_value(page_prog.get("b", {}), "learn"): last_amud = "ב"
            elif get_progress_value(page_prog.get("a", {}), "learn"): last_amud = "א"
            else: return "עדיין לא התחלת" # Fallback
            return f"{content_type} {int_to_gematria(last_page_num)} עמ' {last_amud}"
        else: return f"{content_type} {int_to_gematria(last_page_num)}"

    # --- create_tracking_page (no changes needed from previous correct version) ---
    def create_tracking_page():
        in_progress_items = []
        completed_items = []
        for category, masechtot in data.items():
            for masechta_name, masechta_data in masechtot.items():
                progress = ProgressManager.load_progress(page, masechta_name, category)
                is_complete = is_masechta_completed(category, masechta_name) # Use global helper
                if not progress and not is_complete: continue
                total_pages = get_total_pages(masechta_data)
                completed_pages = get_completed_pages(progress, ["learn"])
                percentage = 0
                if total_pages > 0: percentage = round((completed_pages / total_pages) * 100)
                if is_complete: percentage = 100
                text_color = ft.Colors.WHITE if percentage >= 40 else ft.Colors.BROWN_700
                progress_bar_with_text = ft.Stack([ft.ProgressBar(value=percentage/100 if total_pages > 0 else 0, height=25, border_radius=ft.border_radius.all(5), color=ft.colors.GREEN_700 if is_complete else ft.colors.PRIMARY, bgcolor=ft.colors.with_opacity(0.2, ft.colors.OUTLINE)), ft.Container(content=ft.Text(f"{percentage}%", color=text_color, weight=ft.FontWeight.BOLD, size=13), alignment=ft.alignment.center, height=25)], height=25)
                completion_date_str = ProgressManager.get_completion_date(page, masechta_name, category)
                hebrew_date_str = get_completion_date_string(completion_date_str) if completion_date_str else None
                status_text = f"סיימת ב{hebrew_date_str}" if is_complete and hebrew_date_str else ("סיימת (תאריך לא נשמר)" if is_complete else f"הגעת ל{get_last_page_display(progress, masechta_data)}")
                button_content = ft.Container(expand=True, content=ft.Column([ft.Text(f"{masechta_name} ({category})", size=18, weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER), progress_bar_with_text, ft.Text(status_text, size=14, text_align=ft.TextAlign.CENTER)], spacing=8, alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER), padding=15)
                button_column = ft.Column([ft.ElevatedButton(content=button_content, style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=12), elevation=2, bgcolor=ft.colors.SECONDARY_CONTAINER if not is_complete else ft.colors.with_opacity(0.1, ft.colors.GREEN)), on_click=show_masechta, data={"masechta": masechta_name, "category": category}, expand=True, tooltip=f"פתח את {masechta_name}")], col={"xs": 12, "sm": 6, "md": 4}, expand=True, alignment=ft.MainAxisAlignment.CENTER)
                if is_complete: completed_items.append(button_column)
                else: in_progress_items.append(button_column)
        in_progress_content = in_progress_items if in_progress_items else [ft.Container(ft.Text("אין ספרים בתהליך כעת.", italic=True, text_align=ft.TextAlign.CENTER), padding=20, alignment=ft.alignment.center)]
        completed_content = completed_items if completed_items else [ft.Container(ft.Text("עדיין לא סיימת ספרים.", italic=True, text_align=ft.TextAlign.CENTER), padding=20, alignment=ft.alignment.center)]
        in_progress_responsive_row = ft.ResponsiveRow(controls=in_progress_content, alignment=ft.MainAxisAlignment.START, vertical_alignment=ft.CrossAxisAlignment.START, visible=True, run_spacing=10, spacing=10)
        completed_responsive_row = ft.ResponsiveRow(controls=completed_content, alignment=ft.MainAxisAlignment.START, vertical_alignment=ft.CrossAxisAlignment.START, visible=False, run_spacing=10, spacing=10)
        def on_segmented_button_change(e):
            is_in_progress_selected = e.control.selected == {"in_progress"}
            in_progress_responsive_row.visible = is_in_progress_selected
            completed_responsive_row.visible = not is_in_progress_selected
            page.update()
        segmented_control = ft.SegmentedButton(selected={"in_progress"}, allow_empty_selection=False, show_selected_icon=False, on_change=on_segmented_button_change, segments=[ft.Segment(value="in_progress", label=ft.Text("בתהליך"), icon=ft.Icon(ft.Icons.HOURGLASS_EMPTY_OUTLINED)), ft.Segment(value="completed", label=ft.Text("סיימתי"), icon=ft.Icon(ft.Icons.CHECK_CIRCLE_OUTLINE))])
        return ft.Column(controls=[ft.Container(segmented_control, padding=ft.padding.only(bottom=15), alignment=ft.alignment.center), in_progress_responsive_row, completed_responsive_row], expand=True, horizontal_alignment=ft.CrossAxisAlignment.CENTER)
    # --- End create_tracking_page ---

    # --- navigation_changed (no changes) ---
    def navigation_changed(e):
        selected_index = e.control.selected_index
        if selected_index == 0: page.go("/tracking")
        else: page.go("/books")

    # --- Route Change Logic (ADD SCROLL TO MASECHTA VIEW) ---
    def route_change(e):
        nonlocal current_masechta, current_tab_index, search_tf, search_tab_label # Include search controls

        troute = ft.TemplateRoute(e.route)
        page.views.clear() # Original approach: clear views

        # --- Base View Structure ---
        page.views.append(
            ft.View(
                "/", # Root view path
                [
                    appbar,
                    # Content placeholder
                    navigation_bar,
                ],
                padding=0
            )
        )

        # --- Determine Content and Nav Bar State ---
        if troute.match("/tracking") or troute.route == "/":
            page.views[0].controls.insert(1, create_tracking_page())
            navigation_bar.selected_index = 0
            # Reset search field text and hide search tab label when leaving books view
            if search_tf: search_tf.value = ""
            if search_tab_label: search_tab_label.visible = False


        elif troute.match("/books"):
            page.views[0].controls.insert(1, show_main_menu())
            navigation_bar.selected_index = 1
            # Ensure search state is reset visually if needed when navigating TO books
            if tabs_control: tabs_control.selected_index = current_tab_index
            if search_tab_label:
                current_search_term = search_tf.value if search_tf else ""
                search_tab_label.visible = (len(current_search_term) >= 2 and search_results_grid and search_results_grid.controls)


        elif troute.match("/masechta/:category/:masechta"):
            category = troute.category
            masechta_name = troute.masechta
            current_masechta = masechta_name

            # Add the masechta view *on top*
            page.views.append(
                ft.View(
                    f"/masechta/{category}/{masechta_name}",
                    [
                        appbar,
                        create_table(category, masechta_name),
                        navigation_bar,
                    ],
                    padding=0,
                    # *** ADDED SCROLL HERE for the entire Masechta view ***
                    scroll=ft.ScrollMode.ADAPTIVE,
                )
            )
            # Keep the navbar selected index as it was

        else:
             page.views[0].controls.insert(1, ft.Text(f"Unknown route: {e.route}", text_align=ft.TextAlign.CENTER))

        page.update()
    # --- End route_change ---

    # --- Initial Setup ---
    page.on_route_change = route_change
    page.go(page.route or "/tracking")

# --- Run the App ---
ft.app(target=main) # Removed assets_dir unless needed
