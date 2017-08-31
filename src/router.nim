import sequtils
import sets

type
  BusTime* = ref object
    hour*, minute*: int
  Station* = string
  LineName* = string
  Stop* = ref object
    station*: Station
    time*: BusTime
  Line* = ref object
    name*: LineName
    stations*: HashSet[Station]
    stops*: seq[Stop]
  Segment* = ref object
    start*: Stop
    final*: Stop
    line*: LineName
  Route* = ref object
    segments*: seq[Segment]
  Schedule* = ref object
    lines*: seq[Line]

converter `$`(x: BusTime): string =
  $(x.hour) & ":" & $(x.minute)

proc `$`(x: Segment): string =
  "{" & x.start.station & " " & x.start.time & "; " & x.final.station & " " & x.final.time & "; " & x.line & "}"

proc `$`(x: Route): string =
  if isNil(x):
    "No route found"
  else:
    $(x.segments[1..x.segments.len - 1])

proc `<`(x, y: BusTime): bool =
  if x.hour < y.hour:
    true
  elif x.hour > y.hour:
    false
  elif x.minute < y.minute:
    true
  else:
    false

proc `==`(x, y: BusTime): bool =
  x.hour == y.hour and x.minute == y.minute

proc `<=`(x, y: BusTime): bool =
  x < y or x == y

proc finalStop(route: Route): Stop =
  if route.segments.len > 0:
    result = route.segments[route.segments.len - 1].final

proc compare(a, b: Route): Route =
  if isNil(a): b
  elif isNil(b): a
  elif a.finalStop().time < b.finalStop().time: a
  else: b

proc join(a: Route; b: Segment): Route =
  result = Route(segments: concat(a.segments, @[b]))

proc getNextSegments(schedule: Schedule; start: Stop): seq[Segment] =
  result = newSeq[Segment](0)
  for line in schedule.lines:
    if not line.stations.contains(start.station):
      continue
    for i in 0..line.stops.len - 1:
      let stop = line.stops[i]
      if start.station == stop.station and start.time <= stop.time:
        if i < line.stops.len - 1:
          result.add(Segment(start: stop, final: line.stops[i + 1], line: line.name))
          break

proc findRoute(schedule: Schedule; destination: Station; currentRoute: Route): Route =
  let startStop = currentRoute.finalStop()
  if startStop.station == destination:
    return currentRoute
  let nextSegments = schedule.getNextSegments(startStop)
  for segment in nextSegments:
    let potentialRoute = schedule.findRoute(destination, currentRoute.join(segment))
    result = result.compare(potentialRoute)

proc findRoute*(schedule: Schedule; start, destination: Station; startTime: BusTime): Route =
  let initialStop = Stop(station: start, time: startTime)
  let initialRoute = Route(segments: @[Segment(final: initialStop)])
  return schedule.findRoute(destination, initialRoute)

when isMainModule:
  let A: Station = "A"
  let B: Station = "B"
  let C: Station = "C"
  let D: Station = "D"
  let E: Station = "E"
  let Line1StopA = Stop(station: A, time: BusTime(hour: 12, minute: 0))
  let Line1StopB = Stop(station: B, time: BusTime(hour: 12, minute: 20))
  let Line1StopC = Stop(station: C, time: BusTime(hour: 12, minute: 45))
  let Line2StopB = Stop(station: B, time: BusTime(hour: 12, minute: 50))
  let Line2StopD = Stop(station: D, time: BusTime(hour: 13, minute: 0))
  let Line2StopE = Stop(station: E, time: BusTime(hour: 13, minute: 10))
  let Line1 = Line(name: "Line 1", stations: [A, B, C].toSet(), stops: @[Line1StopA, Line1StopB, Line1StopC])
  let Line2 = Line(name: "Line 2", stations: [B, D, E].toSet(), stops: @[Line2StopB, Line2StopD, Line2StopE])
  let s = Schedule(lines: @[Line1, Line2])
  echo s.findRoute(A, C, BusTime(hour: 11, minute: 30))
  echo s.findRoute(A, E, BusTime(hour: 11, minute: 0))
  echo s.findRoute(A, A, BusTime(hour: 14, minute: 10))
  echo s.findRoute(A, B, BusTime(hour: 15, minute: 50))
  echo s.findRoute(D, A, BusTime(hour: 11, minute: 45))
