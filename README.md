# humidity-sensor
The idea of this project was to create a streaming pipeline for temperature and humidity readings collected by a Raspberry Pi with an Adafruit BME280 sensor. This was to explore the temperature of my house across the course of a day, in particular to look at the rate of house cooling once heating was turned off in the evening. The stack has been simply designed as an exploration and proof of concept, with opportunity for future cloud migration.

## Pipeline 🔩
<img width="576" height="191" alt="pipeline_schematic drawio" src="https://github.com/user-attachments/assets/1ace2d61-1e2f-4c5d-b250-02559c810812" />

* Python script on Raspberry Pi collects reading from BME280 sensor at specified intervals, and publishes to an Mosquitto MQTT broker topic (default `sensors/indoor`) using a `pi_sensor` MQTT user
* The Mosquitto MQTT broker is hosted locally on an old laptop within a Docker container on the default bridge network
* Telegraf consumes the message using the `telegraf` MQTT user, adds tags and inserts the data into a TimescaleDB database
* The TimescaleDB database is also hosted by the laptop within a Docker container
* Finally, Grafana connects to the TimescaleDB database using a Grafana plugin, and pulls the data into a dashboard
* Grafana is hosted using Docker on the laptop

## Dashboard Example🖥️
<img width="2214" height="1328" alt="image" src="https://github.com/user-attachments/assets/b2244e91-a5b4-4399-86b3-3a70df0871af" />

## Configuration ⚙️
* Clone the repo onto the host system and Raspberry Pi
* Configure Mosquitto users and passwords. For the current setup, there is one user for telegraf called `telegraf` and one user for the sensor called `pi_sensor`
* Setup TimescaleDB tables to hold the data. The current design expects a table with columns `time`, `temperature`, `humidity`
* Configure Grafana dashboard with desired visualisations

## Future Plans 🔮
Many optimisations are possible for this stack, as it is currently a proof of concept. The main next steps are to migrate the pipeline to an AWS stack, which will eliminate the dependency on a local laptop, and should open up access from outside the local network. Other improvements include:
* Update documentation, including more detail on setup dependencies, TimeScaleDB schema
* Improve security with SSL certificates for Mosquitto broker
* Track rate of cooling in the evening
