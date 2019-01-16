#  Coordinator Pattern

OK, as I started adding menu hierarchies, launching ViewControllers from different places, different behaviour at different places in the App, and with gestures meaning different things depending on what was currently displayed, 
it got really tricky and error prone to manage all of this within the ViewControllers themselves, plus they then had to have knowledge of where they were in the overall App state machine (I use the term loosely).


Enter the Coordinator Pattern!

The original concept was presented at [Soroush Khanlou's 2015 NSSpain talk](https://vimeo.com/144116310) The basic idea is that you introduce an intermediate/parent object that coordinates multiple view controllers.

The best (meaning most practical for my case) reference I found for this was on the Swift by Sundell blog: https://www.swiftbysundell.com/posts/navigation-in-swift

In my case, this ended up as an arrangement where any ViewController that 'owns' the screen has an associated Coordinator that deals with starting/ending other ViewControllers (and their associated Coordinator), plus routing certain 'requests' to the appropriate Coordinator or Controller. In addition, each Coordinator can manage an arbitrary number of SubControllers, which handle things like menus and tool overlays, i.e. things that do not use the whole screen, and which ultimately just send requests to the main ViewController. There is *no direct communication* between the main ViewController and the sub-controllers, everything is routed via the Coordinator.

There is a top-level Coordinator (AppCoordinator) that is created in AppDelegate, and which sets up the initial state for the top level logic, sets up a (custom) UINavigationController object that is used by all Coordinators (because we want a navigation stack that spans the entire App), and launches the main screen.<br>
It ends up that, instead of starting/stopping ViewControllers, we now start/stop Coordinators which represent a logical Scene/Activity/Function/Use Case (whatever you want to call it). The Coordinators 'know' what ViewControllers and Sub-Controllers are used within that Activity and coordinate between them. 

Key classes are:

- CoordinatorFactory: contains the (logical) IDs of all valid Coordinators, and can create instances for each ID

- ControllerFactory: contains the (logical) IDs of all valid ViewControllers (and SubControllers), and can create instances for each ID

- CoordinatorDelegate, ControllerDelegate, SubControllerDelegate: interfaces required of Coordinators, Controllers, and sub-Controllers (they have a few extra requirements)

- Coordinator: Base class for all Coordinators. 

- CoordinatedController: base class for all Coordinated ViewControllers

- SImpleCoordinator: a Coordinator that can be used for Activities that only involve 1 ViewController, with no sub-states or sub-controllers (it happens a lot)

- *XXX*Coordinator: the Coordinator associated with Activity *XXX*. These essentially just configure the data structures, launch the main activity (and maybe sub-controller), and override any handling of Controller requests that require special attention (i.e. the generic processing isn't right)


Some nice side effects of all of this were:

- I got to move a lot of boilerplate code to the base classes (and hence remove it from the ViewControllers)

- I was able to make the ViewControllers all behave the same way for common functions

- it turned out that a lot of processing is pretty generic, so the Coordinator and CoordinatedController classes do most of the generic logic

- Coordinators have a parent/child relationship, so they can pass requests up or down the chain of command if needed.


