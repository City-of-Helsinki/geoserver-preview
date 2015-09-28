# geoserver-preview
Lightweight Geoserver layer preview webapp

An express-app running on node, written to make it easier to explore, download, and share geographical data hosted on a Geoserver instance. It serves a page of HTML with a table of (some) data about selected datasets, as well as a map with background tiles for previewing the datasets. In the table are a listing of file formats offered for each dataset and a listing of all available datasets from the server.

### TODO/planned/dreamed:
* Show metadata of vector datasets (currently all datasets shown as rasters through WMS)
* Better UI / don't reload page so often (react.js)
