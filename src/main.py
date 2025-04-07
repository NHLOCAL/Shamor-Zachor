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
            # Consider showing an error message on the page itself
            return ft.Text(f"Error: Masechta '{masechta_name}' not found in category '{category}'.")

        progress = ProgressManager.load_progress(page, masechta_name, category)
        start_page = masechta_data.get("start_page", 1)
        is_daf_type = masechta_data["content_type"] == "דף"

        # --- Store references to checkboxes for easy updates ---
        all_checkboxes_in_view = []
        learn_checkboxes_in_view = [] # Specific list for 'learn' checkboxes
        # ------------------------------------------------------

        def on_change(e):
            d = e.control.data
            ProgressManager.save_progress(
                page, masechta_name, d["daf"], d["amud"], d["column"], e.control.value, category,
            )
            # Update progress dictionary locally for immediate feedback in update_check_all_status
            daf_str = str(d["daf"])
            progress.setdefault(daf_str, {}).setdefault(d["amud"], {})[d["column"]] = e.control.value

            update_masechta_completion_status(category, masechta_name) # Updates the main check icon
            update_check_all_status() # Updates the "check all" checkbox state
            if is_masechta_completed(category, masechta_name):
                 # Only save completion date if it wasn't already completed
                 if not ProgressManager.get_completion_date(page, masechta_name, category):
                    ProgressManager.save_completion_date(page, masechta_name, category)
            page.update() # Update UI after state changes

        def update_check_all_status():
            # Check if ALL 'learn' checkboxes *currently loaded in the view* are checked
            all_checked = all(cb.value for cb in learn_checkboxes_in_view)

            # Update the main "check all" checkbox state without triggering its own on_change
            if check_all_checkbox.value != all_checked:
                 check_all_checkbox.value = all_checked
                 # No page.update() here, assumed to be called by the caller (on_change or check_all)

        def check_all(e):
            new_value = e.control.value
            total_items_to_save = masechta_data["pages"]
            start_page_num = masechta_data.get("start_page", 1)
            is_daf = masechta_data["content_type"] == "דף"

            # Save the state for all items (only affects 'learn' column)
            ProgressManager.save_all_masechta(
                page, masechta_name, total_items_to_save, start_page_num, is_daf, new_value, category
            )

            # --- Update checkboxes in the current view ---
            for cb in all_checkboxes_in_view:
                 # Only visually check/uncheck if the state is different
                 if cb.value != new_value:
                     cb.value = new_value
            # ---------------------------------------------

            # Reload progress after mass update to reflect changes accurately
            nonlocal progress
            progress = ProgressManager.load_progress(page, masechta_name, category)

            update_masechta_completion_status(category, masechta_name)
            page.update()


        # --- Build Header ---
        header_row = ft.ResponsiveRow(
            [
                ft.Container(
                    ft.Text(masechta_data["content_type"], weight=ft.FontWeight.BOLD),
                    padding=ft.padding.symmetric(vertical=10, horizontal=8),
                    alignment=ft.alignment.center_right,
                    col={"xs": 3, "sm": 2, "md": 2, "lg": 1}, # Adjust col spans as needed
                ),
                ft.Container(
                    ft.Text("לימוד וחזרות", weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER),
                    padding=ft.padding.symmetric(vertical=10, horizontal=8),
                    alignment=ft.alignment.center,
                    col={"xs": 9, "sm": 10, "md": 10, "lg": 11}, # Adjust col spans as needed
                ),
            ],
            alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        )

        # --- Build Data Rows ---
        list_items = []
        row_index = 0
        for i in range(start_page, masechta_data["pages"] + start_page):
            daf_str = str(i) # Use string for dictionary keys
            daf_progress = progress.get(daf_str, {})
            amudim_to_process = ["a", "b"] if is_daf_type else ["a"]

            for amud_key in amudim_to_process:
                amud_progress = daf_progress.get(amud_key, {})
                is_amud_b = amud_key == "b"
                amud_symbol = ":" if is_amud_b else ("." if is_daf_type else "")
                row_label = f"{int_to_gematria(i)}{amud_symbol}"

                # Create Checkboxes for this row
                learn_cb = ft.Checkbox(
                    value=get_progress_value(amud_progress, "learn"), on_change=on_change,
                    data={"daf": i, "amud": amud_key, "column": "learn"}, tooltip="לימוד",
                )
                review1_cb = ft.Checkbox(
                    value=get_progress_value(amud_progress, "review1"), on_change=on_change,
                    data={"daf": i, "amud": amud_key, "column": "review1"}, tooltip="חזרה 1",
                )
                review2_cb = ft.Checkbox(
                    value=get_progress_value(amud_progress, "review2"), on_change=on_change,
                    data={"daf": i, "amud": amud_key, "column": "review2"}, tooltip="חזרה 2",
                )
                review3_cb = ft.Checkbox(
                    value=get_progress_value(amud_progress, "review3"), on_change=on_change,
                    data={"daf": i, "amud": amud_key, "column": "review3"}, tooltip="חזרה 3",
                )

                # Store references
                all_checkboxes_in_view.extend([learn_cb, review1_cb, review2_cb, review3_cb])
                learn_checkboxes_in_view.append(learn_cb)

                # Define background color for zebra striping
                row_bgcolor = ft.colors.with_opacity(0.03, ft.colors.SECONDARY_CONTAINER) if row_index % 2 == 0 else None

                # Create the responsive row for this data item
                data_responsive_row = ft.ResponsiveRow(
                    [
                        # Column 1: Label
                        ft.Container(
                            content=ft.Text(row_label, font_family="Heebo"),
                            padding=ft.padding.symmetric(vertical=12, horizontal=8), # Adjust padding
                            alignment=ft.alignment.center_right,
                            col={"xs": 3, "sm": 2, "md": 2, "lg": 1}, # Responsive column span
                        ),
                        # Column 2: Checkboxes
                        ft.Container(
                            content=ft.Row(
                                [learn_cb, review1_cb, review2_cb, review3_cb],
                                alignment=ft.MainAxisAlignment.SPACE_EVENLY, # Distribute checkboxes
                                vertical_alignment=ft.CrossAxisAlignment.CENTER,
                                spacing=2, # Minimal spacing between checkboxes
                                wrap=False, # Prevent wrapping within the row if possible
                                tight=True,
                            ),
                            padding=ft.padding.symmetric(vertical=0, horizontal=5), # Padding around checkboxes
                            alignment=ft.alignment.center,
                            col={"xs": 9, "sm": 10, "md": 10, "lg": 11}, # Responsive column span
                        ),
                    ],
                    vertical_alignment=ft.CrossAxisAlignment.CENTER,
                    # spacing=5, # Optional spacing between the two containers
                    run_spacing=0, # No spacing if it wraps (shouldn't happen here)
                    # Apply background color to the entire row container
                    # bgcolor=row_bgcolor, # Apply zebra stripe to row
                )

                # Add the row and a divider to the list
                # Wrap row in a container for background color application
                list_items.append(
                     ft.Container(
                         content=data_responsive_row,
                         bgcolor=row_bgcolor,
                         border_radius=ft.border_radius.all(4) # Slight rounding if using bgcolor
                     )
                )
                # Add divider, except for the last item
                # if not (i == masechta_data["pages"] + start_page - 1 and amud_key == amudim_to_process[-1]):
                list_items.append(ft.Divider(height=1, thickness=0.5, color=ft.colors.with_opacity(0.15, ft.colors.OUTLINE)))


                row_index += 1 # Increment for next stripe color

        # --- Final Assembly ---
        completion_icons[masechta_name] = ft.Icon(ft.Icons.CIRCLE_OUTLINED) # Initialize icon
        is_completed = update_masechta_completion_status(category, masechta_name) # Update icon based on loaded progress

        check_all_checkbox = ft.Checkbox(
            label="סמן הכל כנלמד",
            on_change=check_all,
            value=is_completed # Initial state based on completion
        )
        # Call update_check_all_status once after all checkboxes are created and stored
        update_check_all_status()

        # Main Header (Masechta Name, Icon, Check All)
        main_header = ft.Row(
            [
                ft.Text(masechta_name, size=24, weight=ft.FontWeight.BOLD),
                completion_icons[masechta_name],
                check_all_checkbox,
            ],
            alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        )

        # Scrollable Column containing the header and list items
        content_column = ft.Column(
            [
                header_row, # The "פרק | לימוד וחזרות" header
                ft.Divider(height=1, color=ft.colors.with_opacity(0.5, ft.colors.OUTLINE)),
                *list_items # Unpack the list of rows and dividers
            ],
            scroll=ft.ScrollMode.ADAPTIVE, # Enable scrolling
            expand=True, # Allow column to take available vertical space
            spacing=0, # Control spacing manually with dividers
        )

        # Return the Card containing the header and the responsive list
        return ft.Card(
            elevation=2,
            content=ft.Container(
                content=ft.Column(
                    [
                        main_header,
                        ft.Divider(height=5, color=ft.colors.TRANSPARENT), # Spacer
                        content_column, # The scrollable list
                    ],
                    spacing=5,
                    tight=True,
                ),
                padding=15,
                border_radius=ft.border_radius.all(10),
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