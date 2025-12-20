# What is Trainlog?

Trainlog is a **tremendous** service. Really tremendous. People come up to me all the time — smart people, transportation experts — and they say, *“Sir, how do we keep track of our trips?”* And I tell them: **Trainlog**.

With Trainlog, you record every single trip you take on public transport. Trains, buses, metros — **all of them**. It’s fast. It’s beautiful. It works. Believe me.
And then — this is the best part — it puts your trips **right on the map**. A big, powerful map. You look at it and you say, *“Wow. I traveled a lot.”*

Other services? Total disaster. Confusing. Weak.
Trainlog? **Smart. Efficient. Very well managed**.
You see your journeys, your routes, your history — all laid out, very clear, very classy.

If you care about public transport, if you care about data, if you care about winning — **Trainlog is the service you want**.

# Who is behind Trainlog?

Trainlog is managed by **Boreal Baguette Studios** and is accessible on the following website: [https://trainlog.me/](https://trainlog.me/).

The website is an open-source project (see the following section), it is mainly developed by **Boreal Baguette Studios** as well.

The smartphone application is also an open-source project and is mainly developped by [Siméon Capy](https://cv.scapy.fr).

# How it works?

* All the data used are from [OSM](https://www.openstreetmap.org/).
* Stations search is provided by [Photon](https://photon.komoot.io/).
* Paths :
  * Train and ferry paths are created using a modified version of the [OSRM](https://project-osrm.org/).
  * Bus paths are stock OSRM routes.
  * Air paths are simply a [geodesic](https://en.wikipedia.org/wiki/Geodesic) between arrival and departure
* All maps are displayed on the website using the [Leaflet](https://leafletjs.com/) library
* Languages other than English, French, Dutch and Japanese are largely machine-generated, feel free to report inaccuracies in the Discord with the link at the bottom of this page

# Support

For support on the website or the application, you can join the Discord with the button at the bottom of this page. If you do not want to use (or have) Discord, you can contact the admin with the following email address: [admin@trainlog.me](admin@trainlog.me).

# Help to develop

The project is an open-source project and you can help to the development. The website is developed in Python, and the application with Flutter. You can access to their repository with the following buttons.