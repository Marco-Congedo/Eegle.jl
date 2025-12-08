# Styles used for the visual appearance of the graphical interface (buttons, tables, titles).

number_inuput_style = Styles("color" => :white, "font-weight" => "600")

path_button_style = Styles(CSS("font-weight" => "bold", "background-color" => "#CCCCCC", "box-shadow" => "rgba(0, 0, 0, 0.3) 0px 0px 0px 1px", "color" => "black",
                                "font-size" => "12px", "padding" => "4px 8px", "width" => "140px", "height" => "28px", "border-radius" => "5px"),
                            CSS(":hover", "background-color" => "#BBBBBB"),
                            CSS(":focus", "box-shadow" => "rgba(0, 0, 0, 0.5) 0px 0px 0px 3px")
)


download_button_style = Styles( CSS("font-weight" => "700", "background-color" => "grey"), 
                                        CSS(":hover", "background-color" => "#ccc"), 
                                        CSS(":focus", "box-shadow" => "rgba(0, 0, 0, 0.5) 0px 0px 5px"),)


overwrite_button_style = Styles( CSS("font-weight" => "700", "background-color" => "grey"), 
                                        CSS(":hover", "background-color" => "#ccc"), 
                                        CSS(":focus", "box-shadow" => "rgba(0, 0, 0, 0.5) 0px 0px 5px"),)


header_style_1 = Styles("font-weight"=>"700","flex"=>"2","padding"=>"8px","color"=>"#111")
header_style_2 = Styles("font-weight"=>"700","flex"=>"1","padding"=>"8px","color"=>"#111")

table_header_style = Styles(
                    "border-bottom"=>"2px solid white",
                    "background-color"=>"#fff",
                    "margin-bottom"=>"4px"
                )

rows_style_1 = Styles("flex"=>"1","padding"=>"6px 8px","color"=>"#111")
rows_style_2 = Styles("flex"=>"2","padding"=>"6px 8px","color"=>"#111")

table_rows_style = Styles(
                            "border-bottom"=>"1px solid #555",
                            "background-color"=>"#fff",
                            "margin-bottom"=>"2px"
                        )


table_style = Styles("gap"=>"2px","background-color"=>"#fff","padding"=>"4px","border-radius"=>"6px")

title_style = "font-size: 24px; font-weight: bold; margin-bottom: 20px;"
