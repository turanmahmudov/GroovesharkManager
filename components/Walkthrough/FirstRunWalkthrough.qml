import QtQuick 2.3
import Ubuntu.Components 1.1

// Initial Walkthrough tutorial
Walkthrough {
    id: walkthrough
    objectName: "walkthroughPage"

    appName: "Grooveshark Manager"

    onFinished: {
        walkthrough.visible = false
        pageStack.pop()
        firstRun = false
        setKey("firstRun", "1")
    }

    model: [
        Slide1{},
        Slide2{},
        Slide3{},
        Slide4{},
        Slide5{},
        Slide6{}
    ]
}
