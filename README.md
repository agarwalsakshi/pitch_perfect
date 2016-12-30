# Pitch Perfect

![Platform iOS](https://img.shields.io/badge/platform-iOS-blue.svg)

This is an implementation of Pitch Perfect, the first project in the iOS Developer Nanodegree. It does not quite follow the code written throughout the Introduction to iOS Development with Swift course, so it is not recommended to refer to this version of the application while taking the course or discussing the material with students.

## Known Issues

- Nothing is there to warn the user if they have denied us access to the microphone. Behavior to handle this would be well outside the scope of the class, so an alert has not been implemented.
- Can't get recording to resume correctly after being interrupted (say, by a phone call), so the application punts, presents an alert, and makes the user restart.
- AVAudioEngine kills and resets itself whenever there's a route change, so I'm not sure how to resume playing audio automatically if someone plugs headphones in.
