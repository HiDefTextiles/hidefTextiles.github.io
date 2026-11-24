# Map of the Sjónabók source manuscripts, numbered as in the project table,
# with a timeline banner and a Denmark side panel.
# Data: manuscripts.csv (project table, one row per book) and places.csv
# (coordinates; one row per place a book is tied to, main place first).
# Sources per row; see also https://github.com/HiDefTextiles/Sjonabok/issues/15
# Usage: LC_ALL=C.UTF-8 Rscript manuscript_map.R   -> manuscript_map.html
library(readr)
library(dplyr)
library(leaflet)
library(htmlwidgets)
library(htmltools)
library(maps)
library(mapdata)   # offline coastline, so the map reads even without tiles

# HI palette: made = HI blue, owned = HI teal, later owned / uncertain / held = grey
role_col <- c(made = "#10099F", owned = "#2DD2C0", `later owned` = "#9E9E9E",
              uncertain = "#9E9E9E", held = "#9E9E9E", `family link` = "#9E9E9E")

# One row per book (the project table) and one row per place tied to a book
books <- read_csv("manuscripts.csv", show_col_types = FALSE) |>
  mutate(
    order = map_no,
    label = ifelse(is.na(when_start), paste0(order, "?"), as.character(order)),
    # timeline dot: the date on record, else the middle of the estimated range
    dot = ifelse(date_on_record, when_start, (when_start + when_end) / 2)
  )

places <- read_csv("places.csv", show_col_types = FALSE) |>
  left_join(select(books, id, order, who, when_label, confidence, source, repository, label), by = "id") |>
  mutate(
    colour = unname(role_col[role]),
    first = step == 1,
    popup = sprintf(
      "<b>%s. %s</b><br>%s<br><i>%s</i><br>%s: <b>%s</b>%s<br><small>%s</small><br>Confidence: %s<br>Now held: <b>%s</b><br><small>Source: %s</small><br><a href='%s' target='_blank'>Museum record</a>",
      order, id, who, when_label, role, place,
      ifelse(is.na(when), "", paste0(" (", when, ")")), note, confidence, repository, source, url)
  )

# timeline colour = role at the book's first place (grey if not mapped)
all_tl <- books |>
  left_join(places |> filter(first) |> select(id, colour), by = "id") |>
  mutate(colour = coalesce(colour, "#9E9E9E"))

pl_is <- filter(places, role != "held")   # Iceland
pl_dk <- filter(places, role == "held")   # Copenhagen

# Numbered markers: the first place is a filled circle, later places a smaller
# ring with the same number, joined to the earlier one by a dashed line
add_numbers <- function(map, data) {
  num_label <- function(col) labelOptions(noHide = TRUE, direction = "center", textOnly = TRUE,
                                         style = list(color = col, `font-weight` = "700",
                                                      `font-size` = "12px"))
  for (b in unique(data$id)) {
    path <- data |> filter(id == b) |> arrange(step)
    if (nrow(path) > 1)
      map <- addPolylines(map, lng = path$lon, lat = path$lat, color = "#10099F",
                          weight = 2, opacity = 0.7, dashArray = "5 5")
  }
  later <- filter(data, !first)
  first <- filter(data, first)
  if (nrow(later))
    map <- addCircleMarkers(map, data = later, ~lon, ~lat, radius = 10, color = ~colour,
                            weight = 3, fillColor = "white", fillOpacity = 1,
                            popup = ~popup, label = ~label,
                            labelOptions = num_label("#10099F"))
  addCircleMarkers(map, data = first, ~lon, ~lat, radius = 13, color = "white", weight = 2,
                   fillColor = ~colour, fillOpacity = 1, popup = ~popup, label = ~label,
                   labelOptions = num_label("white"))
}

# Base map: tiles plus an offline coastline
base_map <- function(region, ...) {
  leaflet(options = leafletOptions(...)) |>
    # OpenStreetMap's own tiles: no API key (CARTO now answers "API key required")
    addTiles(attribution = '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors') |>
    addPolygons(data = map("worldHires", region, fill = TRUE, plot = FALSE),
                color = "#10099F", weight = 1, opacity = 0.5,
                fillColor = "#10099F", fillOpacity = 0.05)
}

m_is <- base_map("Iceland", zoomSnap = 0.25) |>
  fitBounds(-24.4, 63.3, -13.4, 66.6) |>
  add_numbers(pl_is) |>
  addLegend("topright", colors = c("#10099F", "#2DD2C0", "#9E9E9E"),
            labels = c("made here (attributed)", "owned here", "later owner / family link / weak / held"),
            title = "Place", opacity = 1) |>
  addControl(HTML("<b>Filled</b> = main place (project table)<br><b>Ring</b> + dashed line = other place<br>tied to the same book"),
             position = "topright") |>
  addControl(HTML(paste("Numbers as in the project table; '?' = no date on record.<br>",
                        "Not mapped (place unresolved): 2 Öðrumgarður, 3 Steinsstaðir, 9 Hóll.")),
             position = "bottomleft")

m_dk <- base_map("Denmark", zoomControl = FALSE, attributionControl = FALSE, zoomSnap = 0.25) |>
  fitBounds(8.0, 54.5, 13.4, 57.8) |>
  add_numbers(pl_dk)

# ── Timeline banner: same numbers on a time axis ─────────────────────────────
timeline_svg <- function(d, from = 1600, to = 1900, w = 1000) {
  x0 <- 30; x1 <- w - 130                     # axis; the right end holds "undated"
  sx <- function(y) x0 + (y - from) / (to - from) * (x1 - x0)
  dated <- d |> filter(!is.na(when_start)) |> arrange(when_start, order)
  undated <- d |> filter(is.na(when_start))

  # greedy lanes so circles and range bars never overlap
  lane_end <- numeric(0); dated$lane <- NA
  for (i in seq_len(nrow(dated))) {
    left <- min(sx(dated$when_start[i]), sx(dated$dot[i]) - 13)
    right <- max(sx(dated$when_end[i]), sx(dated$dot[i]) + 13)
    l <- which(lane_end < left - 4)[1]
    if (is.na(l)) { l <- length(lane_end) + 1 }
    lane_end[l] <- right; dated$lane[i] <- l
  }
  lane_y <- function(l) 16 + (l - 1) * 24
  h <- lane_y(max(dated$lane)) + 40
  axis_y <- h - 22

  circle <- function(cx, cy, colour, label, title)
    sprintf('<g><title>%s</title><circle cx="%.1f" cy="%.1f" r="12" fill="%s" stroke="white" stroke-width="2"/><text x="%.1f" y="%.1f" text-anchor="middle" font-size="12" font-weight="700" fill="white">%s</text></g>',
            htmlEscape(title), cx, cy, colour, cx, cy + 4, label)

  ticks <- seq(ceiling(from / 25) * 25, to, by = 25)
  parts <- c(
    sprintf('<line x1="%d" x2="%d" y1="%d" y2="%d" stroke="#10099F" stroke-width="1.5"/>', x0, x1, axis_y, axis_y),
    sprintf('<line x1="%.1f" x2="%.1f" y1="%d" y2="%d" stroke="#10099F"/><text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#333">%s</text>',
            sx(ticks), sx(ticks), axis_y, axis_y + (ifelse(ticks %% 100 == 0, 6, 3)),
            sx(ticks), axis_y + 17, ifelse(ticks %% 50 == 0, ticks, "")),
    with(dated, sprintf('<line x1="%.1f" x2="%.1f" y1="%.1f" y2="%.1f" stroke="%s" stroke-opacity="0.35" stroke-width="8" stroke-linecap="round"/>',
                        sx(when_start), sx(when_end), lane_y(lane), lane_y(lane), colour)),
    with(dated, circle(sx(dot), lane_y(lane), colour, label,
                       paste0(order, ". ", id, ", ", when_label))),
    if (nrow(undated)) sprintf('<text x="%d" y="14" font-size="11" fill="#333">no date on record</text>', x1 + 30),
    if (nrow(undated)) with(undated, circle(x1 + 45 + (seq_along(order) - 1) * 30, 36, colour, label,
                         paste0(order, ". ", id, ", ", when_label)))
  )
  HTML(sprintf('<svg viewBox="0 0 %d %d" width="100%%" role="img" aria-label="Timeline of the manuscripts" font-family="sans-serif">%s</svg>',
               w, h, paste(parts, collapse = "")))
}

timeline <- div(class = "timeline",
  h4("Timeline: dot at a bar end = date on record; dot mid-bar = estimated range; ? = no date on record"),
  timeline_svg(all_tl))

# Iceland with a narrow Denmark panel beside it (not to scale, no sea in between).
# The Denmark map rides along as appended content, so saveWidget can still
# write one self-contained file.
m_is$sizingPolicy$browser$fill <- FALSE
m_is$elementId <- "map-is"; m_dk$elementId <- "map-dk"

# Heights follow the width, so neither map pads Iceland with sea
m <- m_is |>
  prependContent(tags$style(HTML(
    "body { padding: 8px !important; }
     #htmlwidget_container { display: flex; flex-wrap: wrap; gap: 8px; align-items: flex-start; }
     .timeline { flex: 0 0 100%; }
     .timeline h4, .dk-panel h4 { font: 600 13px sans-serif; color: #10099F; margin: 0 0 4px; }
     #map-is { flex: 4; min-width: 0; }
     .leaflet-tile-pane { filter: grayscale(1) sepia(0.2) hue-rotate(190deg) saturate(1.3) brightness(1.12) contrast(0.72); opacity: 0.85; }
     .dk-panel { flex: 1; min-width: 0; }
     .dk-panel p { font: 12px sans-serif; color: #444; margin: 4px 0 0; }
     #map-is { width: auto !important; height: min(92vh, 50vw) !important; }
     #map-dk { width: 100% !important; height: min(70vh, 24vw) !important; }"))) |>
  prependContent(timeline) |>
  appendContent(div(class = "dk-panel", h4("Denmark (inset, not to scale)"), m_dk,
                    p("Where they are now: 1–9 in Þjóðminjasafn Íslands, Reykjavík; 10 (N.453.a, dated 1780) in Nationalmuseet, Copenhagen, origin unknown.")))

saveWidget(m, "manuscript_map.html", selfcontained = TRUE, title = "Sjónabók manuscripts")
