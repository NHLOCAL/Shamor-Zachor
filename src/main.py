import flet as ft
from flet import Page
from hebrew_numbers import int_to_gematria

from progress_manager import ProgressManager, get_completed_pages
from data_loader import load_data, get_total_pages, get_completion_date_string

# --- get_progress_value function ---
def get_progress_value(item, key, default=False):
    if isinstance(item, dict):
        return item.get(key, default)
    elif isinstance(item, bool):
        return item
    return default

# --- main function ---
def main(page: Page):
    page.title = "שמור וזכור"
    page.rtl = True
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = ft.Theme(color_scheme_seed=ft.Colors.BROWN)
    page.vertical_alignment = ft.MainAxisAlignment.START
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    # Remove page-level padding, apply it within views
    # page.padding = 20 # REMOVED
    page.scroll = "adaptive"

    # --- State Variables ---
    current_tab_index = 0
    current_tracking_segment = {"in_progress"}
    data = load_data()
    if not data:
        page.overlay.append(ft.SnackBar(ft.Text("אופס! לא הצלחנו לטעון את הנתונים")))
        page.update()
        return

    completion_icons = {}
    current_masechta = None
    search_results_tab = None
    search_results_grid = None
    tabs_control = None
    navigation_bar = None
    search_tf = None
    search_tab_label = None

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
        automatically_imply_leading=False,
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

    # --- Navigation Functions ---
    def go_back(e):
        if len(page.views) > 1:
            page.views.pop()
            top_view_route = page.views[-1].route
            if top_view_route == "/tracking":
                navigation_bar.selected_index = 0
            elif top_view_route == "/books":
                navigation_bar.selected_index = 1
            page.go(top_view_route)

    def navigation_changed(e):
        selected_index = e.control.selected_index
        if selected_index == 0:
            page.go("/tracking")
        else:
            page.go("/books")

    def show_masechta(e):
        page.go(f"/masechta/{e.control.data['category']}/{e.control.data['masechta']}")
    # --- End Navigation Functions ---


    # --- Completion Status & Data Helpers ---
    def update_masechta_completion_status(category: str, masechta_name: str):
        # ... (implementation as before) ...
        progress = ProgressManager.load_progress(page, masechta_name, category)
        masechta_data = data[category].get(masechta_name)
        if not masechta_data: return False
        is_completed = is_masechta_completed_helper(category, masechta_name) # Use helper
        icon_widget = completion_icons.get(masechta_name)
        if icon_widget:
            icon_widget.icon = ft.Icon(ft.Icons.CHECK_CIRCLE) if is_completed else ft.Icon(ft.Icons.CIRCLE_OUTLINED)
            icon_widget.color = ft.Colors.GREEN if is_completed else ft.Colors.GREY_400
        return is_completed


    def is_masechta_completed_helper(category: str, masechta_name: str) -> bool:
        # ... (implementation as before) ...
        _progress = ProgressManager.load_progress(page, masechta_name, category)
        _masechta_data = data[category].get(masechta_name)
        if not _masechta_data: return False
        _total = get_total_pages(_masechta_data)
        if _total == 0: return False
        _completed = get_completed_pages(_progress, ["learn"]) # Check only 'learn'
        return _completed >= _total

    # --- End Completion Status & Data Helpers ---


    # --- View Creation Functions (No padding changes needed inside these) ---
    def create_table(category: str, masechta_name: str):
        # ... (implementation as before) ...
        masechta_data = data[category].get(masechta_name)
        if not masechta_data: return ft.Text(f"Error: Masechta '{masechta_name}' not found.")
        progress = ProgressManager.load_progress(page, masechta_name, category)
        start_page = masechta_data.get("start_page", 1)
        is_daf_type = masechta_data["content_type"] == "דף"
        all_checkboxes_in_view = []
        learn_checkboxes_in_view = []
        def on_change(e):
            nonlocal progress
            d = e.control.data
            ProgressManager.save_progress(page, masechta_name, d["daf"], d["amud"], d["column"], e.control.value, category)
            progress = ProgressManager.load_progress(page, masechta_name, category) # Reload
            update_masechta_completion_status(category, masechta_name)
            update_check_all_status()
            is_now_complete = is_masechta_completed_helper(category, masechta_name)
            if is_now_complete and not ProgressManager.get_completion_date(page, masechta_name, category):
                ProgressManager.save_completion_date(page, masechta_name, category)
            page.update()
        def update_check_all_status():
            is_complete = is_masechta_completed_helper(category, masechta_name)
            if 'check_all_checkbox' in locals() and check_all_checkbox.value != is_complete:
                 check_all_checkbox.value = is_complete
        def check_all(e):
            new_value = e.control.value
            total_items_to_save = masechta_data["pages"]
            start_page_num = masechta_data.get("start_page", 1)
            is_daf = masechta_data["content_type"] == "דף"
            ProgressManager.save_all_masechta(page, masechta_name, total_items_to_save, start_page_num, is_daf, new_value, category)
            for cb in learn_checkboxes_in_view:
                if cb.value != new_value: cb.value = new_value
            if not new_value:
                for cb in all_checkboxes_in_view:
                    if cb.data["column"] != "learn" and cb.value: cb.value = False
            nonlocal progress
            progress = ProgressManager.load_progress(page, masechta_name, category) # Reload
            update_masechta_completion_status(category, masechta_name)
            update_check_all_status()
            page.update()
        header_row = ft.ResponsiveRow([ft.Container(ft.Text(masechta_data["content_type"], weight=ft.FontWeight.BOLD), padding=ft.padding.symmetric(vertical=10, horizontal=8), alignment=ft.alignment.center_right, col={"xs": 3, "sm": 2, "md": 2, "lg": 1}), ft.Container(ft.Text("לימוד וחזרות", weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER), padding=ft.padding.symmetric(vertical=10, horizontal=8), alignment=ft.alignment.center, col={"xs": 9, "sm": 10, "md": 10, "lg": 11})], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, vertical_alignment=ft.CrossAxisAlignment.CENTER)
        list_items = []
        row_index = 0
        for i in range(start_page, masechta_data["pages"] + start_page):
            daf_str = str(i); daf_progress = progress.get(daf_str, {}); amudim_to_process = ["a", "b"] if is_daf_type else ["a"]
            for amud_key in amudim_to_process:
                amud_progress = daf_progress.get(amud_key, {}); is_amud_b = amud_key == "b"; amud_symbol = ":" if is_amud_b else ("." if is_daf_type else ""); row_label = f"{int_to_gematria(i)}{amud_symbol}"
                learn_cb = ft.Checkbox(value=get_progress_value(amud_progress, "learn"), on_change=on_change, data={"daf": i, "amud": amud_key, "column": "learn"}, tooltip="לימוד")
                review1_cb = ft.Checkbox(value=get_progress_value(amud_progress, "review1"), on_change=on_change, data={"daf": i, "amud": amud_key, "column": "review1"}, tooltip="חזרה 1")
                review2_cb = ft.Checkbox(value=get_progress_value(amud_progress, "review2"), on_change=on_change, data={"daf": i, "amud": amud_key, "column": "review2"}, tooltip="חזרה 2")
                review3_cb = ft.Checkbox(value=get_progress_value(amud_progress, "review3"), on_change=on_change, data={"daf": i, "amud": amud_key, "column": "review3"}, tooltip="חזרה 3")
                all_checkboxes_in_view.extend([learn_cb, review1_cb, review2_cb, review3_cb]); learn_checkboxes_in_view.append(learn_cb)
                row_bgcolor = ft.colors.with_opacity(0.03, ft.colors.SECONDARY_CONTAINER) if row_index % 2 == 0 else None
                data_responsive_row = ft.ResponsiveRow([ft.Container(content=ft.Text(row_label, font_family="Heebo"), padding=ft.padding.symmetric(vertical=12, horizontal=8), alignment=ft.alignment.center_right, col={"xs": 3, "sm": 2, "md": 2, "lg": 1}), ft.Container(content=ft.Row([learn_cb, review1_cb, review2_cb, review3_cb], alignment=ft.MainAxisAlignment.SPACE_EVENLY, vertical_alignment=ft.CrossAxisAlignment.CENTER, spacing=2, wrap=False, tight=True), padding=ft.padding.symmetric(vertical=0, horizontal=5), alignment=ft.alignment.center, col={"xs": 9, "sm": 10, "md": 10, "lg": 11})], vertical_alignment=ft.CrossAxisAlignment.CENTER, run_spacing=0)
                list_items.append(ft.Container(content=data_responsive_row, bgcolor=row_bgcolor, border_radius=ft.border_radius.all(4)))
                list_items.append(ft.Divider(height=1, thickness=0.5, color=ft.colors.with_opacity(0.15, ft.colors.OUTLINE)))
                row_index += 1
        completion_icons[masechta_name] = ft.Icon(ft.Icons.CIRCLE_OUTLINED)
        is_completed_initially = is_masechta_completed_helper(category, masechta_name)
        update_masechta_completion_status(category, masechta_name)
        check_all_checkbox = ft.Checkbox(label="סמן הכל כנלמד", on_change=check_all, value=is_completed_initially)
        update_check_all_status()
        main_header = ft.Row([ft.IconButton(ft.icons.ARROW_BACK, tooltip="חזור", on_click=go_back), ft.Text(masechta_name, size=24, weight=ft.FontWeight.BOLD, expand=True, text_align=ft.TextAlign.CENTER), completion_icons[masechta_name], check_all_checkbox], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, vertical_alignment=ft.CrossAxisAlignment.CENTER)
        content_column = ft.Column([header_row, ft.Divider(height=1, color=ft.colors.with_opacity(0.5, ft.colors.OUTLINE)), *list_items], scroll=ft.ScrollMode.ADAPTIVE, expand=True, spacing=0)
        return ft.Card(elevation=2, content=ft.Container(content=ft.Column([main_header, ft.Divider(height=5, color=ft.colors.TRANSPARENT), content_column], spacing=5, tight=True), padding=15, border_radius=ft.border_radius.all(10)))

    def show_main_menu():
        # ... (implementation as before) ...
        nonlocal tabs_control, current_tab_index, search_tf, search_tab_label, search_results_grid, search_results_tab
        sections = {"תנ״ך": list(data.get("תנ״ך", {}).keys()), "תלמוד בבלי": list(data.get("תלמוד בבלי", {}).keys()), "תלמוד ירושלמי": list(data.get("תלמוד ירושלמי", {}).keys()), "רמב״ם": list(data.get("רמב״ם", {}).keys()), "שולחן ערוך": list(data.get("שולחן ערוך", {}).keys())}
        def create_masechta_button(masechta, category, visible=True, include_category=False):
            is_complete = is_masechta_completed_helper(category, masechta); button_content = None; check_icon = ft.Icon(ft.icons.CHECK_CIRCLE, color=ft.colors.GREEN, size=18)
            if include_category:
                masechta_text = ft.Text(masechta, size=16); category_text = ft.Text(category, size=13, color=ft.colors.GREY_600)
                if is_complete: masechta_display = ft.Row([check_icon, masechta_text], alignment=ft.MainAxisAlignment.CENTER, vertical_alignment=ft.CrossAxisAlignment.CENTER, spacing=4, tight=True)
                else: masechta_display = ft.Row([masechta_text], alignment=ft.MainAxisAlignment.CENTER)
                button_content = ft.Column([masechta_display, category_text], tight=True, horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=2); height = 75
            else:
                masechta_text = ft.Text(masechta, size=16, text_align=ft.TextAlign.CENTER)
                if is_complete: button_content = ft.Row([check_icon, masechta_text], alignment=ft.MainAxisAlignment.CENTER, vertical_alignment=ft.CrossAxisAlignment.CENTER, spacing=4, tight=True)
                else: button_content = masechta_text
                height = 65
            return ft.ElevatedButton(content=button_content, data={"masechta": masechta, "category": category}, on_click=show_masechta, style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=10), padding=ft.padding.symmetric(horizontal=8, vertical=5)), tooltip=f"פתח את {masechta}", width=150, height=height, visible=visible)
        def perform_search(search_term):
            results = []; search_term_lower = search_term.lower()
            for category, masechtot in data.items():
                for masechta_name in masechtot:
                    if search_term_lower in masechta_name.lower(): results.append(create_masechta_button(masechta_name, category, include_category=True))
            return results
        def search_changed(e):
            nonlocal search_results_grid, search_results_tab, tabs_control, search_tab_label; search_term = e.control.value.strip()
            if not all([search_results_grid, search_results_tab, tabs_control, search_tab_label]): return
            search_tab_index = len(tabs_control.tabs) - 1
            if len(search_term) >= 2:
                search_results = perform_search(search_term); search_results_grid.controls = search_results
                if search_results:
                    search_tab_label.visible = True
                    if tabs_control.selected_index != search_tab_index: tabs_control.selected_index = search_tab_index
                else:
                    search_tab_label.visible = False
                    if tabs_control.selected_index == search_tab_index: tabs_control.selected_index = current_tab_index
            else:
                search_results_grid.controls = []; search_tab_label.visible = False
                if tabs_control.selected_index == search_tab_index: tabs_control.selected_index = current_tab_index
            page.update()
        def on_tab_change(e):
            nonlocal current_tab_index; selected_index = e.control.selected_index; search_tab_index = len(tabs_control.tabs) - 1
            if selected_index != search_tab_index: current_tab_index = selected_index
        if search_tf is None: search_tf = ft.TextField(hint_text="חיפוש ספר...", prefix_icon=ft.Icons.SEARCH, on_change=search_changed, width=400, border_radius=30, border_color=ft.colors.PRIMARY, bgcolor=ft.colors.with_opacity(0.05, ft.colors.SECONDARY_CONTAINER), filled=True, dense=True, content_padding=12)
        if tabs_control is None:
            tab_list = []
            for section_name, masechtot in sections.items():
                book_buttons = [create_masechta_button(masechta, section_name) for masechta in masechtot]
                tab_content = ft.Container(content=ft.GridView(controls=book_buttons, runs_count=3, max_extent=160, run_spacing=10, spacing=10, padding=10), expand=True)
                tab_list.append(ft.Tab(text=section_name, content=tab_content))
            search_results_grid = ft.GridView(controls=[], runs_count=3, max_extent=160, run_spacing=10, spacing=10, padding=10)
            search_tab_label = ft.Row([ft.Icon(ft.Icons.SEARCH), ft.Text("חיפוש")], tight=True, spacing=5, visible=False)
            search_results_tab = ft.Tab(tab_content=search_tab_label, content=ft.Container(content=search_results_grid, expand=True))
            tab_list.append(search_results_tab)
            tabs_control = ft.Tabs(selected_index=current_tab_index, tabs=tab_list, expand=1, on_change=on_tab_change)
        else:
            for i, section_name in enumerate(sections.keys()):
                book_buttons = [create_masechta_button(masechta, section_name) for masechta in sections[section_name]]
                try:
                    grid_view = tabs_control.tabs[i].content.content
                    if isinstance(grid_view, ft.GridView): grid_view.controls = book_buttons
                except AttributeError: pass
            tabs_control.selected_index = current_tab_index
            current_search_term = search_tf.value if search_tf else ""
            if search_tab_label: search_tab_label.visible = (len(current_search_term) >= 2 and search_results_grid and search_results_grid.controls)
        return ft.Column([ft.Container(search_tf, padding=ft.padding.only(bottom=10)), tabs_control], horizontal_alignment=ft.CrossAxisAlignment.CENTER, expand=True)

    def create_tracking_page():
        """Creates the Tracking view with segments and styled cards."""
        nonlocal current_tracking_segment  # Use and update global state

        in_progress_items = []
        completed_items = []

        # --- Populate items based on progress and completion ---
        for category, masechtot in data.items():
            for masechta_name, masechta_data in masechtot.items():
                progress = ProgressManager.load_progress(page, masechta_name, category)
                # Use the helper function to check completion status
                is_complete = is_masechta_completed_helper(category, masechta_name)

                # Skip items that were never started and are not marked complete
                if not progress and not is_complete:
                    continue

                # Calculate progress percentage
                total_pages = get_total_pages(masechta_data)
                completed_pages = get_completed_pages(progress, ["learn"])
                percentage = 0
                if total_pages > 0:
                    percentage = round((completed_pages / total_pages) * 100)
                if is_complete: # Ensure completed items show 100%
                    percentage = 100

                # Determine text color for progress bar percentage
                text_color = ft.Colors.WHITE if percentage >= 40 else ft.Colors.BROWN_700

                # Create the progress bar with text overlay
                progress_bar = ft.ProgressBar(
                    value=percentage / 100 if total_pages > 0 else 0,
                    height=25,
                    border_radius=ft.border_radius.all(5),
                    color=ft.colors.GREEN_700 if is_complete else ft.colors.PRIMARY,
                    bgcolor=ft.colors.with_opacity(0.2, ft.colors.OUTLINE)
                )
                progress_text = ft.Container(
                    content=ft.Text(
                        f"{percentage}%",
                        color=text_color,
                        weight=ft.FontWeight.BOLD,
                        size=13
                    ),
                    alignment=ft.alignment.center,
                    height=25
                )
                progress_bar_with_text = ft.Stack([progress_bar, progress_text], height=25)

                # Determine status text (completion date or last page)
                completion_date_str = ProgressManager.get_completion_date(page, masechta_name, category)
                hebrew_date_str = get_completion_date_string(completion_date_str) if completion_date_str else None
                if is_complete:
                    status_text = f"סיימת ב{hebrew_date_str}" if hebrew_date_str else "סיימת (תאריך לא נשמר)"
                else:
                    status_text = f"הגעת ל{get_last_page_display(progress, masechta_data)}"

                # Create the content for the button card
                button_content = ft.Container(
                    expand=True,
                    content=ft.Column(
                        [
                            ft.Text(
                                f"{masechta_name} ({category})",
                                size=18,
                                weight=ft.FontWeight.BOLD,
                                text_align=ft.TextAlign.CENTER
                            ),
                            progress_bar_with_text,
                            ft.Text(
                                status_text,
                                size=14,
                                text_align=ft.TextAlign.CENTER
                            ),
                        ],
                        spacing=8,
                        alignment=ft.MainAxisAlignment.CENTER,
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER
                    ),
                    padding=15
                )

                # --- Define background color based on completion status ---
                button_bgcolor = None # Default (uses theme button color)
                if is_complete:
                    # Color for COMPLETED cards (Light greenish/brownish)
                    # Option 1: Light Green Accent
                    button_bgcolor = ft.colors.SURFACE_VARIANT
                    # Option 2: Light Brown
                    # button_bgcolor = ft.colors.BROWN_100
                    # Option 3: Transparent Green
                    # button_bgcolor = ft.colors.with_opacity(0.15, ft.colors.GREEN_700)
                else:
                    # Color for IN-PROGRESS cards (Neutral light color from theme)
                    # Option 1: Secondary Container (usually light brown/beige in this theme)
                    button_bgcolor = ft.colors.SURFACE_VARIANT
                    # Option 2: Surface Variant (another theme color)
                    # button_bgcolor = ft.colors.SURFACE_VARIANT
                    # Option 3: Lightest Brown
                    # button_bgcolor = ft.colors.BROWN_50

                # Create the button column for the responsive row
                button_col = ft.Column(
                    [
                        ft.ElevatedButton(
                            content=button_content,
                            style=ft.ButtonStyle(
                                shape=ft.RoundedRectangleBorder(radius=12),
                                elevation=2,
                                # --- Apply the determined background color ---
                                bgcolor=button_bgcolor,
                            ),
                            on_click=show_masechta,
                            data={"masechta": masechta_name, "category": category},
                            expand=True,
                            tooltip=f"פתח את {masechta_name}"
                        )
                    ],
                    # Responsive column settings
                    col={"xs": 12, "sm": 6, "md": 4},
                    expand=True,
                    alignment=ft.MainAxisAlignment.CENTER
                )
                # --- End of button creation ---

                # Add the button column to the appropriate list
                if is_complete:
                    completed_items.append(button_col)
                else:
                    in_progress_items.append(button_col)

        # --- Create Responsive Rows with empty state handling ---
        in_progress_content = in_progress_items if in_progress_items else [
            ft.Container(
                ft.Text("אין ספרים בתהליך כעת.", italic=True, text_align=ft.TextAlign.CENTER),
                padding=20,
                alignment=ft.alignment.center
            )
        ]
        completed_content = completed_items if completed_items else [
            ft.Container(
                ft.Text("עדיין לא סיימת ספרים.", italic=True, text_align=ft.TextAlign.CENTER),
                padding=20,
                alignment=ft.alignment.center
            )
        ]

        in_progress_row = ft.ResponsiveRow(
            controls=in_progress_content,
            alignment=ft.MainAxisAlignment.START,
            vertical_alignment=ft.CrossAxisAlignment.START,
            # Set visibility based on stored state
            visible=(current_tracking_segment == {"in_progress"}),
            run_spacing=10,
            spacing=10
        )
        completed_row = ft.ResponsiveRow(
            controls=completed_content,
            alignment=ft.MainAxisAlignment.START,
            vertical_alignment=ft.CrossAxisAlignment.START,
            # Set visibility based on stored state
            visible=(current_tracking_segment == {"completed"}),
            run_spacing=10,
            spacing=10
        )

        # --- Segmented Button Handler ---
        def on_segmented_button_change(e):
            nonlocal current_tracking_segment  # Update global state
            current_tracking_segment = e.control.selected
            is_in_progress = current_tracking_segment == {"in_progress"}
            in_progress_row.visible = is_in_progress
            completed_row.visible = not is_in_progress
            page.update()

        # --- Create Segmented Button using state ---
        segmented_control = ft.SegmentedButton(
            # Set initial selection from stored state
            selected=current_tracking_segment,
            allow_empty_selection=False,
            show_selected_icon=False,
            on_change=on_segmented_button_change,
            segments=[
                ft.Segment(
                    value="in_progress",
                    label=ft.Text("בתהליך"),
                    icon=ft.Icon(ft.Icons.HOURGLASS_EMPTY_OUTLINED)
                ),
                ft.Segment(
                    value="completed",
                    label=ft.Text("סיימתי"),
                    icon=ft.Icon(ft.Icons.CHECK_CIRCLE_OUTLINE)
                ),
            ]
        )

        # --- Return the final Column for the tracking page ---
        return ft.Column(
            controls=[
                ft.Container(
                    segmented_control,
                    padding=ft.padding.only(bottom=15),
                    alignment=ft.alignment.center
                ),
                in_progress_row,
                completed_row,
            ],
            expand=True,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            scroll="adaptive"
        )
        
        def on_segmented_button_change(e):
            nonlocal current_tracking_segment; current_tracking_segment = e.control.selected; is_in_progress = current_tracking_segment == {"in_progress"}
            in_progress_row.visible = is_in_progress; completed_row.visible = not is_in_progress; page.update()
        segmented_control = ft.SegmentedButton(selected=current_tracking_segment, allow_empty_selection=False, show_selected_icon=False, on_change=on_segmented_button_change, segments=[ft.Segment(value="in_progress", label=ft.Text("בתהליך"), icon=ft.Icon(ft.Icons.HOURGLASS_EMPTY_OUTLINED)), ft.Segment(value="completed", label=ft.Text("סיימתי"), icon=ft.Icon(ft.Icons.CHECK_CIRCLE_OUTLINE))])
        return ft.Column(controls=[ft.Container(segmented_control, padding=ft.padding.only(bottom=15), alignment=ft.alignment.center), in_progress_row, completed_row], expand=True, horizontal_alignment=ft.CrossAxisAlignment.CENTER)

    def get_last_page_display(progress, masechta_data):
        # ... (implementation as before) ...
        if not progress: return "עדיין לא התחלת"
        valid_keys = [k for k, v in progress.items() if k.isdigit() and (get_progress_value(v.get("a", {}), "learn") or (masechta_data.get("content_type") == "דף" and get_progress_value(v.get("b", {}), "learn")))]
        if not valid_keys: return "עדיין לא התחלת"
        try: last_page_num = max(int(k) for k in valid_keys)
        except ValueError: return "שגיאה בנתונים"
        last_page_str = str(last_page_num); content_type = masechta_data.get("content_type", "עמוד")
        if content_type == "דף":
            last_amud = ""; page_prog = progress.get(last_page_str, {})
            if get_progress_value(page_prog.get("b", {}), "learn"): last_amud = "ב"
            elif get_progress_value(page_prog.get("a", {}), "learn"): last_amud = "א"
            else: return "עדיין לא התחלת"
            return f"{content_type} {int_to_gematria(last_page_num)} עמ' {last_amud}"
        else: return f"{content_type} {int_to_gematria(last_page_num)}"
    # --- End View Creation Functions ---


    # --- Route Change Logic (ADD PADDING WRAPPER) ---
    def route_change(e):
        """Handles route changes and builds the view stack with content padding."""
        nonlocal current_masechta, current_tab_index, search_tf, search_tab_label, current_tracking_segment

        troute = ft.TemplateRoute(e.route)
        page.views.clear()

        # --- Define content based on route ---
        main_content = None
        nav_bar_index = 0 # Default to tracking

        if troute.match("/tracking") or troute.route == "/":
            main_content = create_tracking_page()
            nav_bar_index = 0
            if search_tf: search_tf.value = ""
            if search_tab_label: search_tab_label.visible = False

        elif troute.match("/books"):
            main_content = show_main_menu()
            nav_bar_index = 1
            if search_tab_label:
                 current_search_term = search_tf.value if search_tf else ""
                 search_tab_label.visible = (len(current_search_term) >= 2 and search_results_grid and search_results_grid.controls)

        elif troute.match("/masechta/:category/:masechta"):
            category = troute.category
            masechta_name = troute.masechta
            current_masechta = masechta_name

            # Add the underlying view first (Tracking or Books)
            if navigation_bar.selected_index == 0:
                 page.views.append(ft.View("/tracking", [appbar, ft.Container(create_tracking_page(), expand=True, padding=ft.padding.symmetric(horizontal=15, vertical=10)), navigation_bar], padding=0))
            else:
                 page.views.append(ft.View("/books", [appbar, ft.Container(show_main_menu(), expand=True, padding=ft.padding.symmetric(horizontal=15, vertical=10)), navigation_bar], padding=0))

            # Add Masechta view on top (content doesn't need extra padding, Card has it)
            page.views.append(
                ft.View(
                    f"/masechta/{category}/{masechta_name}",
                    [
                        appbar,
                        create_table(category, masechta_name), # Table Card already has padding
                        navigation_bar,
                    ],
                    padding=0, # No padding for the view itself
                    scroll=ft.ScrollMode.ADAPTIVE,
                )
            )
            page.update() # Update after adding both views
            return # Exit route_change early for masechta view

        else: # Unknown route
            main_content = ft.Text(f"Unknown route: {e.route}", text_align=ft.TextAlign.CENTER)
            nav_bar_index = 0

        # --- Build the main view (Tracking or Books) ---
        if main_content:
            # *** Wrap main_content in a Container with padding ***
            content_wrapper = ft.Container(
                content=main_content,
                expand=True, # Make container fill space between appbar and navbar
                padding=ft.padding.symmetric(horizontal=15, vertical=10) # Adjust padding as needed
            )
            page.views.append(
                ft.View(
                    e.route, # Use the actual route ("/tracking" or "/books")
                    [
                        appbar,
                        content_wrapper, # Add the padded container here
                        navigation_bar,
                    ],
                    padding=0 # Keep View padding 0
                )
            )
            navigation_bar.selected_index = nav_bar_index # Set correct navbar index

        page.update()
    # --- End route_change ---


    # --- Initial Setup ---
    page.on_route_change = route_change
    page.go(page.route or "/tracking")


# --- Run the App ---
ft.app(target=main)
