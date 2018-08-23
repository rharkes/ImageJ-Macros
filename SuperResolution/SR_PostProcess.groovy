/*************************************************************
*	Super Resolution PostProcessing Macro
*
*	Version 0.1 (just a GUI)
*
*
*************************************************************/

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
	public static void TheMainProgram(GUI_Settings Settings) { 
		print "---AUTOMATIC THUNDERSTORM---\n"
		
	}
	public void Functioncollection(){
	}
}

class GUI_Settings { //check the settings in the textplanel and store them
	public File input
	public File output
	public String suffix
	public Boolean TM_Bool //temporal median
	public Long TM_WindowSize
	public Long TM_Offset
	public Boolean CC_Bool //chromatic aberation correction
	public String filtering_string

	public GUI_settings(TextPanel TP){
		
	}
	public GUI_settings(File file){
		
	}
	public Save_GUI_settings(File file){
		
	}
}

/*************************************************************
*	TextPanel Class
*************************************************************/
class TextPanel extends JPanel  implements ActionListener { //The ButtonPanel gets a reference to this.
	// members :
	private JCheckBox MedSubstr_CB
	private JSpinner MedSubstr_Offs
	private JSpinner MedSubstr_Wind
	private JButton OpenFileBtn
	private JFileChooser filechooser
	private File FilePath
	public void actionPerformed(ActionEvent e){ 
		String com = e.getActionCommand()
		switch (com) {
			case "Path = " + FilePath.toString():
			case "Choose Path":
				filechooser = new JFileChooser()
				filechooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
				filechooser.showSaveDialog(null)
				FilePath = filechooser.getSelectedFile()
				OpenFileBtn.setText("Path = " + FilePath.toString())
			case "Temporal Median Subtraction":
				if (MedSubstr_CB.isSelected()){
					MedSubstr_Offs.setVisible(true)
					MedSubstr_Wind.setVisible(true)
				} else {
					MedSubstr_Offs.setVisible(false)
					MedSubstr_Wind.setVisible(false)
				}		
				return
		}
			
	}
	public loadsettings(){
		filechooser = new JFileChooser()
		filechooser.showSaveDialog(null)
		File file = filechooser.getSelectedFile()
		GUI_Settings G = GUI_settings(file)
		
	}
	public savesettings(){
	}
	public reset(){
		FilePath = null
		OpenFileBtn.setText("Choose Path")
		MedSubstr_CB.setSelected(true)
		MedSubstr_Offs.setVisible(true)
		MedSubstr_Wind.setVisible(true)
		MedSubstr_Offs.setValue(1000)
		MedSubstr_Wind.setValue(501)
	}
	public TextPanel(){
		setLayout(new BoxLayout(this, BoxLayout.Y_AXIS))
		//Choose Directory
		OpenFileBtn = new JButton("Choose Path");
    	OpenFileBtn.setBackground(SystemColor.menu);
    	OpenFileBtn.setAlignmentX(OpenFileBtn.LEFT_ALIGNMENT)
    	OpenFileBtn.addActionListener(this)		
		
		//Median subtraction checkbox
		MedSubstr_CB = new JCheckBox ("Temporal Median Subtraction",true)
		MedSubstr_CB.setHorizontalTextPosition(MedSubstr_CB.LEFT)
		MedSubstr_CB.setAlignmentX(MedSubstr_CB.LEFT_ALIGNMENT)
		MedSubstr_CB.addActionListener(this)		

		//Offset
		SpinnerModel SpinOffs = new SpinnerNumberModel(1000, 0, 10000,  100); //min,max,step
		MedSubstr_Offs = new JSpinner(SpinOffs){
        @Override
        public Dimension getMaximumSize() {
            Dimension dim = super.getMaximumSize()
            dim.height = getPreferredSize().height
            dim.width = MedSubstr_CB.getPreferredSize().width
            return dim
        }
		}
		MedSubstr_Offs.setAlignmentX(MedSubstr_Offs.LEFT_ALIGNMENT)

		//Window
		SpinnerModel SpinWind = new SpinnerNumberModel(501, 3, 10001,  2); //min,max,step
		MedSubstr_Wind = new JSpinner(SpinWind){
        @Override
        public Dimension getMaximumSize() {
            Dimension dim = super.getMaximumSize()
            dim.height = getPreferredSize().height
            dim.width = MedSubstr_CB.getPreferredSize().width
            return dim
        }
		}
		MedSubstr_Wind.setAlignmentX(MedSubstr_Wind.LEFT_ALIGNMENT)

		add(OpenFileBtn)
		add(MedSubstr_CB)
		add(MedSubstr_Offs)
		add(MedSubstr_Wind)
	}
}

/*************************************************************
*	ButtonPanel Class (Start & Reset)
*************************************************************/
class ButtonPanel extends JPanel implements ActionListener {
	// members:
	private JButton StartButton
	private JButton ResetButton
	private JButton LoadSButton
	private JButton SaveSButton
	private TextPanel TP //we want to access the text-panel from the button-panel to send it to the FunctionCollection
	// constructors:
	public void actionPerformed(ActionEvent e){ //when a registered button is pressed
		String com = e.getActionCommand()
		Component[] C = TP.getComponents()
		switch (com) {
			case "Start":
				FunctionCollection FC = new FunctionCollection()
				FC.TheMainProgram(GUI_settings(TP)) 
				break
			case "Reset":
				TP.reset()
				break
			case "Load Settings":
				TP.loadsettings()
				break
			case "Save Settings":
				TP.savesettings()
				break
		}
	}
	public ButtonPanel(TextPanel TP) { //creator function
		this.TP = TP
		setLayout(new BoxLayout(this, BoxLayout.X_AXIS))
		// create buttons
		StartButton = new JButton("Start")
		ResetButton = new JButton("Reset")
		LoadSButton = new JButton("Load Settings")
		SaveSButton = new JButton("Save Settings")
		
		// add buttons to current panel
		add(StartButton)
		add(ResetButton)
		add(LoadSButton)
		add(SaveSButton)
		
		// register the current panel as listener for the buttons
		StartButton.addActionListener(this)
		ResetButton.addActionListener(this)
		LoadSButton.addActionListener(this)
		SaveSButton.addActionListener(this)
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
		getContentPane().setLayout(new GridLayout()) 
        getContentPane().add(splitPane) 
		splitPane.setOrientation(JSplitPane.VERTICAL_SPLIT)  // we want it to split the window verticaly
        splitPane.setDividerLocation(300)    
        TextPanel TP = new TextPanel()                       // the initial position of the divider is 200 (our window is 400 pixels high)

        splitPane.setTopComponent(TP)                        // at the top we want our "topPanel"
        splitPane.setBottomComponent(new ButtonPanel(TP))    // and at the bottom we want our "bottomPanel"
	}
}