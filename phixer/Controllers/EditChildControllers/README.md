#  Edit Child Controllers

This folder contains 'child' controllers that implement related subsets of edit controls. <br>
Each controller is responsible for displaying and implementing it's associated editing functions and will call it's delegate update() function when something happens that requires the general UI to be updated.<br>
The parent controller is responsible for setting the view size etc. and it is expected that the child controllers are operating in a relatively small portion of the overall display, e.g. typically a display area for showing menus etc. at the bottom of the screen.<br>
These usually need to be implemented as ViewControllers so that they can launch other screens  etc. plus it also breaks up functionality so that it's not all in one enormous ViewController

