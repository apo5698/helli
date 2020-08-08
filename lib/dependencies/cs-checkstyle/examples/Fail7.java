// Mistake: uses a magic number (10)
/**
 * Command-line utility to generate a list of squares
 *
 * @author Tyler Bletsch (tkbletsc@ncsu.edu)
 * @version 1.0
 */
public class Fail7 {
    /** Title banner for this amazing program */
    private static final String TITLE = "Awesome number square-er by Tyler Bletsch";
    
   /**
     * Square the provided number.
     * @param x  The number to square.
     * @return   The square of the given number.
     */
    private static int square(int x) {
        return x * x;
    }
    
    /**
     * Executed at program launch, prints the squares of integers 0..MAX_VALUE.
     * @param args  Command line arguments, ignored.
     */
    public static void main(String[] args) {
        System.out.println(TITLE);
        for (int i = 0; i <= 10; i++) {
            System.out.print(i);
            System.out.print(" ");
            System.out.println(square(i));
        }
    }
}
