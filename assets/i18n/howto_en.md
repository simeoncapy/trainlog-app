# General

The application is divided in four main parts: the **map**, the **trip list**, the **leaderbord** and the **statistics**. Which are accessible with the navigation bar at the bottom. Other functionnalites are located inside the main menu. You can open it with the floating burger icon :icon(menu): on the top left.

# Map

The map will displays all your trip path. The colours will depend on the transportation mode (your can change the colour palette in the settings). A scheduled trip will be displayed hatched, and an oigoing trip will be coloured in red. Different filters are available to displays specific trips, just click on the bottom right button.

Moreover, three tools are usable to manage the map. The first one :icon(my_location): will recenter the map to your current position (if you accepted Trainlog to access it), and a double tap will reset the zoom value. The second option will auto center the map on your position while moving, tap on :sym(frame_person): to activate it, and :sym(frame_person_off): to disable it. The last one :icon(explore): will reorintate the map to the North.

You can click on any path to display a summary sheet of your trip. From it you can share, edit, duplicate and delete your trip. Concerning the sharing option, you need to enable it in the settings. The trip will be shared as a link.

# Trip list

It will display all your trips, past and future (use the toggle selector at the top), in a paginated view. You can scroll horizontally on the table to display more information about your trips. To display all the details, click on a row to diplay the bottom sheet. If you drag down the table, it will refresh your trip list with the server.

## Add a trip - basics

First select the type of vehicle you used, as it as an impact of the station search. You can then select the stations by entering its name. A minimap can let you check if the choosen selection is correct or not. This is espically useful when a big station is split in different entity (suffixed with letters). You can expand the minimap by clicking on :icon(fullscreen):.

In case the station doesn't exist, you can create a manual station. For this, click on :sym(globe_location_pin): to change the mode. Then enter the name of the station and its coordinates. If you don't know the coordinates, you can also move the pin on the minimap after expanding it.

At the end of the form, you can select one or several operators for the trips. The already existing one will show up. In case the operator doesn't exist, you can validate the field with enter or a comma to create an operator without logo. You can request the logo to be added in the app on the project Discord (check the Trainlog tab).

## Add a trip - dates

Three date modes are available, selectable at the top of the screen:

- **Precise**: Enter the exact departure and arrival dates and times. Both fields include a date picker and a time picker. The timezone is automatically inferred from the station coordinates and displayed below each time field. You can also record the actual delay by expanding the delay section: enter the delay in minutes, or set the actual departure/arrival time directly.
- **Date**: Only enter the travel date (without a time). You can optionally specify the trip duration in hours and minutes.
- **Unknown**: Use this when you don't know the exact date. Select whether the trip is in the past or the future, and optionally enter an approximate duration.

## Add a trip - details

All fields on this page are optional.

You can fill in the **line** number or name, the **material** (rolling stock model), the vehicle **registration** number, your **seat** number, and a free-text **note**.

The **Ticket** section lets you record the ticket price (with a currency picker) and the purchase date.

The **Energy** section lets you specify the traction type of the vehicle: automatic, electric, or fuel.

The **Visibility** section controls who can see this trip: private (only you), friends only, or public.

## Add a trip - path

The path step displays an interactive map that automatically computes the route between your departure and arrival stations. The distance and estimated duration are shown at the top. For rail, metro, and tram trips, you can toggle the **new router** option to use an alternative routing engine — tap the help icon for more details. Once you are satisfied with the path, press **Validate** to save the trip. You can also press **Continue trip** to save and immediately start a new trip with the current arrival station as the new departure.

# Ranking

The ranking page displays the leaderboard of all Trainlog users for each vehicle category.

# Statistics

The statistics page lets you explore your travel data through charts and tables. Use the filter panel at the top to customise the view — tap on it to expand or collapse it.

The available filters are:
- **Vehicle**: the type of transportation to analyse.
- **Year**: filter by a specific year, or select "All years" for the full history. (Disabled when the graph type is set to "Years".)
- **Graph type**: choose what to break down the data by — operator, country, years, material, or itinerary.
- **Unit**: choose the metric — number of trips, distance, duration, or CO2.

Three chart types are available via the selector in the top-right corner:
- **Bar chart**: displays the top 10 entries as a bar chart. A toggle lets you switch between horizontal and vertical orientations.
- **Pie chart**: displays the top 10 entries as a pie chart.
- **Table**: displays the full dataset as a sortable table, with separate columns for past and future trips. A toggle lets you switch between sorting by total value and alphabetical order.

Both past and future trips are shown side by side in all chart types.

# Geolog (Smart Prerecorder)

Geolog is a smart pre-recorder accessible from the main menu. It lets you record your current location at the moment of departure and arrival, then use those two records to create a trip automatically.

Tap the **Record** button to save a geolog. The app will capture your current coordinates and timestamp, then look up the nearest station within the configured radius (adjustable in settings). If several stations are found nearby, a selection dialog will appear so you can pick the right one. If no station is found, the geolog is saved with an unknown location. All data is stored locally on your device only.

To create a trip, select exactly two geologs from the list — the first one will be treated as the departure (marked **D**) and the second as the arrival (marked **A**). Then tap **Create a trip** to open the add trip form pre-filled with the saved locations and timestamps. After the trip is saved, the two geologs are automatically deleted.

You can delete individual geologs by selecting them and tapping **Delete selection**, or remove all of them at once with **Delete all**. The sort order (newest/oldest first) can be toggled with the sort button.