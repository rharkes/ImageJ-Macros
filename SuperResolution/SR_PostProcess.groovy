import java.awt.*
import java.awt.event.*
import javax.swing.*
import java.awt.Container.*

/*************************************************************
*	Main Program
*************************************************************/
public static void main(String[] args) {
	JFrame f = new MyFrame("Super Resolution Post Process Macro")
	f.setVisible(true)
}

/*************************************************************
*	All functions that can be executed (the actuall macro-part of this macro)
*************************************************************/
class FunctionCollection {
	public static void TheMainProgram(TextPanel TP) { //not pretty, but let's just parse the whole textpanel (a good programmer would make a class that checks the input and returns the proper values etc.)
		print "---AUTOMATIC THUNDERSTORM---\n"
		
	}
	public void Functioncollection(){
	}
}

/*************************************************************
*	TextPanel Class
*************************************************************/
class TextPanel extends JPanel  implements ActionListener { //The ButtonPanel gets a reference to this.
	// members :
	private JCheckBox BackSubstr_CB
	public void actionPerformed(ActionEvent e){ 
		print "You clicked subtract background\n"
		
	}
	public TextPanel(){
		BackSubstr_CB = new JCheckBox ("Subtract Background",true)
		this.setAlignmentY(this.CENTER_ALIGNMENT);
		this.setAlignmentX(this.CENTER_ALIGNMENT);
		add(BackSubstr_CB)
		BackSubstr_CB.addActionListener(this)
	}
}

/*************************************************************
*	ButtonPanel Class (Start & Reset)
*************************************************************/
class ButtonPanel extends JPanel implements ActionListener {
	// members:
	private JButton StartButton
	private JButton ResetButton
	private TextPanel TP //we want to access the text-panel from the button-panel to send it to the FunctionCollection
	// constructors:
	public void actionPerformed(ActionEvent e){ //when a registered button is pressed
		String com = e.getActionCommand()
		Component[] C = TP.getComponents()
		switch (com) {
			case "Start":
				FunctionCollection FC = new FunctionCollection()
				FC.TheMainProgram(TP) 
				break
			case "Reset":
				print "You clicked the reset button\n"
				break
		}
	}
	public ButtonPanel(TextPanel TP) { //creator function
		this.TP = TP
		// create buttons
		StartButton = new JButton("Start")
		ResetButton = new JButton("Reset")
		
		// add buttons to current panel
		add(StartButton)
		add(ResetButton)
		
		// register the current panel as listener for the buttons
		StartButton.addActionListener(this)
		ResetButton.addActionListener(this)
	} // ButtonPanel constructor
} // ButtonPanel class

/*************************************************************
MyFrame Class
*************************************************************/
class MyFrame extends JFrame {
	public MyFrame(String s) {
		JSplitPane splitPane = new JSplitPane()
        setSize(400,400)
		setTitle(s)
		setLocation(10,100) // default is 0,0 (top left corner)
		
		// Window Listeners
		addWindowListener(new WindowAdapter() {
			public void windowClosing(WindowEvent e) {
				print "You stopped the program\n"
			}
		})
		// Add Panels
		getContentPane().setLayout(new GridLayout()) //many options here GroupLayout, SpringLayout, CardLayout, BoxLayout, etc. etc.
        getContentPane().add(splitPane) 
		splitPane.setOrientation(JSplitPane.VERTICAL_SPLIT)  // we want it to split the window verticaly
        splitPane.setDividerLocation(300)    
        TextPanel TP = new TextPanel()                       // the initial position of the divider is 200 (our window is 400 pixels high)
        splitPane.setTopComponent(TP)                        // at the top we want our "topPanel"
        splitPane.setBottomComponent(new ButtonPanel(TP))    // and at the bottom we want our "bottomPanel"
	}
}