package pillar.lbs;

/**
 * 
 * @author Sam Meek
 * Part of the LineOfSightCoordinates process
 * Performs the actual line of sight calculations
 *
 */

public class GetHeightICanSee {
	private static final String TAG = null;
	double Easting;
	double Northing;
	static double [] headerData = new double[6];
	double [][] ASCIIData;
	private dhTuple myResult; 
	private double[] myData;
	private double myHeight;
	private double myHeightOffset;
	private static double distanceToTarget;
	
	/**
	 * Default constructor
	 */
	public GetHeightICanSee(){
		
		
	}
	
	/**
	 * 
	 * @param easting: easting coordinate (must be the same projection as the rr data)
	 * @param northing: northing coordinate (must be the same projection as the rr data)
	 * @param rr: an instantiation of the RasterReader class
	 * @param theta: compass bearing
	 * @param elevation: tilt of the mobile device
	 * @param heightOffset: the height of the user above the ground
	 */
	public GetHeightICanSee(double easting, double northing, RasterReader rr, double theta, 
			double elevation, double heightOffset){
	
		GetHeightICanSee.headerData = rr.getASCIIHeader();
		
		ASCIIData = new double[(int)headerData[1]][(int)headerData[0]];
		
		this.ASCIIData = rr.getASCIIData();
		
		this.Easting = getMyx(easting);
		this.Northing = getMyy(northing);
		myHeight = - 1;
		
		myHeightOffset = heightOffset;
		
		try{
			myHeight = ASCIIData[(int)Northing][(int)Easting] + myHeightOffset;
			
			}
		catch (ArrayIndexOutOfBoundsException e){
			
			}
		
		myResult = heightICanSee(makeAngle(theta), Math.toRadians(elevation), ASCIIData, headerData[4],
				(int)Easting, (int)Northing, myHeight);
		myData = new double[3];
		myData = conMyResult(myResult);
	}
	
	
	/**
	 * @return myData: a getter for the result
	 */
	public double[] getMyResult(){
		return myData;
	}
		
	/**
	 * 
	 * @return arrayCoords: return the array coordinates 
	 */
	public double[] getArrayCoords(){
		double[] arrayCoords = new double[2];
		arrayCoords[0] = (getMyx(getMyResult()[2]))/headerData[0];
		arrayCoords[1] = (getMyy(getMyResult()[3]))/headerData[1];
		return arrayCoords;
		
	}
	
	/**
	 * @return myPos: this is for plotting the screen coordinates with the view to having a map underneath
	 */
	public double[] getMyPositionDraw(){
		double[] myPos = new double[2];
		myPos [0] = (Easting)/headerData[0];
		myPos [1] = (Northing)/headerData[1];
		return myPos;
	}
	/**
	 * 
	 * @param dh 
	 * @return myResult
	 */
	private double [] conMyResult(dhTuple dh){
		double [] myResult = new double[5];
		try{
		
		myResult[0] = dh.d;
		myResult[1] = dh.h;
		myResult[2] =  (int) ((int) ((dh.x) * headerData[4]) + headerData[2]);;
		myResult[3] = (int) ((int) ((int) ((headerData[0] - dh.y - 1)  * headerData[4])) + headerData[3]);
		myResult[4] = (int) ASCIIData[(int)Northing][(int)Easting];
		}
		catch (NullPointerException e){
			
		
			for(int i = 0; i < 4; i++){
				myResult[i] = -1;
			}
			
		}
		
		return myResult;
	}
	
	/**
	 * 
	 * @param Easting: the Easting of the point
	 * @return i: decimal of the distance of easting across the surface
	 */
	private static double getMyx(double Easting){
		double i = ((Easting - headerData[2])) / headerData[4];
		return i;
	}
	
	/**
	 * 
	 * @param Northing: the Northing of the point
	 * @return i: decimal of the distance of Northing across the surface
	 */
	private static double getMyy(double Northing){
		double i = (headerData[0] - ((Northing - headerData[3])) / headerData[4]);
		return i;
	}
	

	/**
	 * 
	 * @author Sam Meek
	 * A simple helper class because Java doesn't return tuple
	 */
	private static class xyTuple {
		double x, y;
		int xcell, ycell;
		
		public xyTuple(double x, double y, int xcell, int ycell) {
			this.x = x;
			this.y = y;
			this.xcell = xcell;
			this.ycell = ycell;
		}
		
		public String toString() {
			return "(" + x + "," + y + "," + xcell + "," + ycell + ")";
		}
	}
	
	
	/**
	 * 
	 * @param degrees
	 * @return radians
	 */
	private static double makeAngle(double degrees) {
		double realDegrees = 360 - 
			(degrees - 90);
		return Math.toRadians(realDegrees);
	}
	
	/**
	 * 
	 * @param theta: bearing
	 * @param d: the distance to test along the LoS
	 * @param cellsize: cellsize of the raster
	 * @return
	 */
	private static xyTuple getCellAt(double theta, double d, double cellsize) {
			double x = Math.cos(theta) * d;
			double y = Math.sin(theta) * d;
			int xcell = (int) Math.floor(x / cellsize);
			int ycell = (int) Math.floor(y / cellsize);
			return new xyTuple(x, y, xcell, ycell);
	}
	
	/**
	 * 
	 * @param elevation: tilt
	 * @param d: distance to test along the LoS
	 * @param myHeight: the height of the user (the height from the raster + the height of the user)
	 * @return
	 */
	private static double getHeightAt(double elevation, double d, double myHeight) {
		return (d * Math.tan(elevation)) + myHeight;
	}
	
	public static class dhTuple {
		double d, h, x, y;
		
		public dhTuple(double d, double h, int y, int x) {
			this.d = d;
			this.h = h;
			this.y = y;
			this.x = x;
		}
		
		
	}
		
	private static dhTuple heightICanSee(double theta, double elevation, double[][] universe, 
								  double cellsize, int myx, int myy, double myHeight) {
		double d = cellsize * 4 + 0.1;
		double dincr = cellsize;
		xyTuple xy = null;
		
		try { 
			while (d < (universe[0].length * cellsize)/2) {
				xy = getCellAt(theta, d, cellsize);
				
				double h = getHeightAt(elevation, d, myHeight);
				
				if (h < universe[myy-xy.ycell - 1][myx + xy.xcell]){
	
					distanceToTarget = d;
					return new dhTuple(d, (universe[myy-xy.ycell - 1][myx + xy.xcell]),myy-xy.ycell - 1, myx + xy.xcell);
				}
				
				
				d += dincr;
				
			}
		} catch (ArrayIndexOutOfBoundsException e) {
			return null;
		}
		return null;
	}
	
	/**
	 * @return getter for myheight
	 */
	public double getMyHeight(){
		return myHeight;
	}
	
	/**
	 * 
	 * @return myArrayCoords: returns user position on the array
	 */
	public double[] getMyArrayCoords(){
		double[] myArrayCoords = new double[2];
		
		myArrayCoords[0] = getMyx(getMyResult()[2]);
		myArrayCoords[1] = getMyy(getMyResult()[3]);
		
		return myArrayCoords;
		
	}
	/**
	 * 
	 * @return distanceToTarget: the distance from the user to the target
	 */
	public double getDistanceToTarget(){
		return distanceToTarget;
		
	}
	
	
	
}
