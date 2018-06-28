import java.awt.*
import java.awt.event.*
import javax.swing.*
import java.awt.Container.*

/*************************************************************
*	Main Program
*************************************************************/
public static void main(String[] args) {
	JFrame f = new MyFrame("My Hello World Frame")
	f.show()
}

/*************************************************************
*	TextPanel Class
*************************************************************/
class TextPanel extends JPanel {
	public void paintComponent(Graphics g) {
			super.paintComponent(g)
			Font f = new Font("SansSerif", Font.BOLD, 14)
			Font fi = new Font("SansSerif", Font.BOLD + Font.ITALIC, 14)
			FontMetrics fm = g.getFontMetrics(f)
			FontMetrics fim = g.getFontMetrics(fi)
			int cx = 75 int cy = 100
			g.setFont(f)
			g.drawString("Hello, ", cx, cy)
			cx += fm.stringWidth("Hello, ")
			g.setFont(fi)
			g.drawString("World!", cx, cy)
		} 
}

/*************************************************************
*	ButtonPanel Class
*************************************************************/
class ButtonPanel extends JPanel implements ActionListener {
	// members:
	private JButton redButton
	private JButton blueButton
	private TextPanel TP //we want to access the text-panel from the button-panel
	// constructors:
	public void actionPerformed(ActionEvent e){ //when a registered button is pressed
		String com = e.getActionCommand()
		Component[] C = TP.getComponents()
		switch (com) {
			case "RED":
				print "You clicked the "+com+" button!\n"
				if (C.length==0){
					JButton extraButton = new JButton("Extra")
					TP.add(extraButton)
				}else {
					C[0].setVisible(true)
				}
				break
			case "BLUE":
				print "You clicked the "+com+" button!!\n"
				if (C.length>0){
					C[0].setVisible(false)
				}
				break
		}
		repaint()
		revalidate()
	}
	public ButtonPanel(TextPanel TP) {
		this.TP = TP
		// create buttons
		redButton = new JButton("RED")
		blueButton = new JButton("BLUE")
		
		// add buttons to current panel
		add(redButton)  // add button to current panel
		add(blueButton) // add button to current panel
		
		// register the current panel as listener for the buttons
		redButton.addActionListener(this)  
		blueButton.addActionListener(this) 
	} // ButtonPanel constructor
} // ButtonPanel class

/*************************************************************
MyFrame Class
*************************************************************/
class MyFrame extends JFrame {
	public MyFrame(String s) {
		JSplitPane splitPane = new JSplitPane()
        JPanel topPanel = new JPanel()         // our top component
        JPanel bottomPanel = new JPanel()      // our bottom component
        setSize(400,400)
		setTitle(s)
		setLocation(10,200) // default is 0,0 (top left corner)
		
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
        TextPanel TP = new TextPanel()                        // the initial position of the divider is 200 (our window is 400 pixels high)
        splitPane.setTopComponent(TP)                        // at the top we want our "topPanel"
        splitPane.setBottomComponent(new ButtonPanel(TP))      // and at the bottom we want our "bottomPanel"
	}
}