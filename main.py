import flet as ft
from backend import save_progress, save_all_masechta, load_progress, load_shas_data
from hebrew_numbers import int_to_gematria, gematria_to_int

def main(page: ft.Page):
    page.title = "שמור וזכור"
    page.rtl = True
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = ft.Theme(color_scheme_seed=ft.colors.BROWN)
    page.vertical_alignment = ft.MainAxisAlignment.START
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    page.padding = 20
    page.scroll = "adaptive"

    shas_data = load_shas_data("shas.json")

    if not shas_data:
        page.add(ft.Text("Error loading shas data."))
        return

    current_masechta = None

    def create_table(masechta_name):
        masechta_data = shas_data.get(masechta_name)
        if not masechta_data:
            page.snack_bar = ft.SnackBar(ft.Text(f"Error: Masechta '{masechta_name}' not found in data."))
            page.snack_bar.open = True
            page.update()
            return None

        progress = load_progress(masechta_name)

        def on_change(e):
            daf = int(e.control.data["daf"])
            amud = e.control.data["amud"]
            save_progress(masechta_name, daf, amud, e.control.value)
            update_completion_status(masechta_name) # Update completion status
            page.update()

        def check_all(e):
            
            for row in table.rows:
                row.cells[1].content.value = e.control.value
                row.cells[2].content.value = e.control.value
            # עדכון כל הערכים במסכת הנוכחית בהתאם לערך שנבחר
            
            save_all_masechta(masechta_name, len(table.rows), e.control.value)
            
            # עדכון סטטוס ההשלמה של המסכת
            update_completion_status(masechta_name)
            
            # עדכון תצוגת הדף
            page.update()

                
        table = ft.DataTable(
            columns=[
                ft.DataColumn(ft.Text("דף")),
                ft.DataColumn(ft.Text("עמוד א")),
                ft.DataColumn(ft.Text("עמוד ב")),
            ],
            rows=[], # Rows will be added dynamically
            border=ft.border.all(1, "black"),
            column_spacing=30,
        )

        for i in range(1, masechta_data["pages"] + 1):
           table.rows.append(
                ft.DataRow(
                    cells=[
                        ft.DataCell(ft.Container(ft.Text(int_to_gematria(i)), height=40)),
                        ft.DataCell(
                            ft.Checkbox(
                                value=progress.get(str(i), {}).get("a", False),
                                on_change=on_change,
                                data={"daf": i, "amud": "a"},
                            )
                        ),
                        ft.DataCell(
                            ft.Checkbox(
                                value=progress.get(str(i), {}).get("b", False),
                                on_change=on_change,
                                data={"daf": i, "amud": "b"},
                            )
                        ),
                    ],
                   
                )
           )


        return ft.Card(
            content=ft.Container(
                content=ft.Column(
                    [
                        ft.Row([ft.Text(masechta_name, size=20, weight=ft.FontWeight.BOLD), completion_indicators.get(masechta_name)], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                        ft.Checkbox(label="בחר הכל", on_change=check_all),
                        table
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                ),
                padding=20,
            ),
        )



    def show_masechta(e):
        nonlocal current_masechta
        current_masechta = e.control.data
        page.views.clear()
        page.views.append(
            ft.View(
                "/masechta",
                [
                    ft.AppBar(title=ft.Text(current_masechta), leading=ft.IconButton(icon=ft.icons.ARROW_BACK, on_click=show_main_menu)),
                    create_table(current_masechta)
                ],
                vertical_alignment=ft.MainAxisAlignment.START,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                scroll="always"
            )
        )
        page.update()



    completion_indicators = {} # Store completion indicators for each masechta

    def update_completion_status(masechta_name):

        progress = load_progress(masechta_name)
        masechta_data = shas_data.get(masechta_name)
        total_pages = 2 * masechta_data["pages"] # Assuming every daf has 2 amudim
        completed_pages = 0
        for i in range(1, masechta_data["pages"] + 1):

             if progress.get(str(i), {}).get("a", False):
                 completed_pages += 1
             if progress.get(str(i), {}).get("b", False):
                  completed_pages += 1

        if completed_pages == total_pages:

             completion_indicators[masechta_name] = ft.Icon(ft.icons.CHECK_CIRCLE, color=ft.colors.GREEN)
        else:
           completion_indicators[masechta_name] = ft.Text("")



    def show_main_menu(e=None):
        nonlocal current_masechta
        current_masechta = None
        
        # Initialize Completion indicators
        for masechta in shas_data:
            update_completion_status(masechta)
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
                        color=ft.colors.ON_PRIMARY,
                        center_title=True,
                        bgcolor=ft.colors.PRIMARY,
                    ),
                    ft.Container(
                        content=ft.Column(
                           [
                                ft.Text("בחר מסכת:", size=24, weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER, style=ft.TextStyle(color=ft.colors.BLUE_GREY_700)),
                                ft.GridView(
                                    controls=[
                                        ft.ElevatedButton(
                                            text=masechta,
                                            data=masechta,
                                            on_click=show_masechta,
                                            style=ft.ButtonStyle(
                                                shape=ft.RoundedRectangleBorder(radius=10),
                                                padding=15,
                                            ),
                                            width=150,
                                            height=50,
                                        )
                                        for masechta in shas_data

                                    ],
                                    runs_count=3,  # Number of columns in the grid
                                    max_extent=200, # set the width of the button to fill the gridview
                                    run_spacing=10,
                                    spacing=10,
                                    padding=10,
                                ),
                            ],
                            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                            scroll=ft.ScrollMode.AUTO,

                        ),
                        expand=True,

                    )

                ],
                vertical_alignment=ft.MainAxisAlignment.START,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,

            )
        )
        page.update()

    show_main_menu()

ft.app(target=main)