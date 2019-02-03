#  Tool Child Controllers

This folder contains 'child' controllers that implement an edit tool  <br>
Each controller is responsible for displaying and implementing it's associated editing functions and will call it's delegate update() function when something happens that requires the general UI to be updated.<br>
The parent controller is responsible for setting the view size etc. <br>
Unlike menus, tools take up a larger portion of the screen, and also typically control an underlying filter that affects the main display.<br>

There are 2 types of tools: 

- paneltool: occupies roughly the lower half of the screen
- fulltool: occupies the whole screen (usually because they may need to overlay something on the main display)

These usually need to be implemented as ViewControllers so that they can launch other screens  etc. plus it also breaks up functionality so that it's not all in one enormous ViewController

