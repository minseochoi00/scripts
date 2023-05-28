Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;

public class KeyTesterForm : Form
{
    public KeyTesterForm()
    {
        InitializeComponent();
    }
    
    private void InitializeComponent()
    {
        this.Text = "Keyboard Key Tester";
        this.StartPosition = FormStartPosition.CenterScreen;
        this.KeyDown += KeyTesterForm_KeyDown;
    }
    
    private void KeyTesterForm_KeyDown(object sender, KeyEventArgs e)
    {
        MessageBox.Show("Key Pressed: " + e.KeyCode, "Key Tester");
    }
}

public class Program
{
    public static void Main()
    {
        Application.Run(new KeyTesterForm());
    }
}
"@

[Program]::Main()