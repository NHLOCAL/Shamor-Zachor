import flet as ft
from backend import save_progress, load_progress, load_shas_data
from hebrew_numbers import int_to_gematria


def main(page: ft.Page):
    page.title = "Shamor & Zachor"
    page.rtl = True
    page.vertical_alignment = ft.MainAxisAlignment.START # Align content to the top
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    page.padding = 20
    page.scroll = "always"


    shas_data = load_shas_data("shas.json")

    if not shas_data:
        page.add(ft.Text("Error loading shas data."))
        return

    current_masechta = None

    def create_table(masechta_name):
        masechta_data = shas_data.get(masechta_name)
        if not masechta_data:
             page.add(ft.Text(f"Error: Masechta '{masechta_name}' not found in data."))
             return None

        progress = load_progress(masechta_name)


        def on_change(e):
            daf = int(e.control.data["daf"])
            amud = e.control.data["amud"]
            save_progress(masechta_name, daf, amud, e.control.value)
            page.update()

        table = ft.DataTable(
            columns=[
                ft.DataColumn(ft.Text("דף")),
                ft.DataColumn(ft.Text("עמוד א")),
                ft.DataColumn(ft.Text("עמוד ב")),
            ],
            rows=[
                ft.DataRow(
                    cells=[
                        ft.DataCell(ft.Text(int_to_gematria(i))),
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
                    ]
                )
                for i in range(1, masechta_data["pages"] + 1)
            ],
            border=ft.border.all(1, "black"),
        )

        return ft.Container(
            content=ft.Column(
                [ft.Text(masechta_name, size=20), table],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            padding=10,
            border_radius=10,
        )


    page.add(
         ft.Column(
             [create_table(masechta) for masechta in shas_data.keys() if create_table(masechta) is not None],
             scroll="always",
             spacing=20,
         )
    )


    def show_masechta(e):
        nonlocal current_masechta
        current_masechta = e.control.data
        page.clean() # clear the page
        page.add(ft.IconButton(icon=ft.icons.ARROW_BACK, on_click=show_main_menu), create_table(current_masechta))
        page.update()



    def show_main_menu(e):
        nonlocal current_masechta
        current_masechta = None
        page.clean()
        page.add(
            ft.Column(
                [
                    ft.Text("בחר מסכת:", size=24, weight=ft.FontWeight.BOLD),  # Title with bold font
                    ft.GridView(  # Use GridView for better layout
                        [
                            ft.ElevatedButton(
                                text=masechta,
                                data=masechta,
                                on_click=show_masechta,
                                width=150,  # Set a fixed width for buttons
                                height=50,
                            )
                            for masechta in shas_data
                        ],
                        runs_count=3,  # Number of columns in the grid
                        run_spacing=10,  # Spacing between columns
                        spacing=10,  # Spacing between rows
                        padding=10,
                        child_aspect_ratio=1.5, # adjust the aspect ratio of the buttons
                        
                    )

                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER
            )
        )
        page.update()


    show_main_menu(None)



ft.app(target=main)