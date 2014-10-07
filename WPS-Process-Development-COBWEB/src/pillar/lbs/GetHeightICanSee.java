package pillar.lbs;



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
	public GetHeightICanSee(){
		//constructor to use the inner methods
		
	}
	//rr = the class which parses the raster
	//theta = compass
	//elevation = tilt
	//heightOffset = height of the device above the surface model (usually 1.75m, my height at eye level)
	public GetHeightICanSee(double easting, double northing, RasterReader rr, double theta, 
			double elevation, double heightOffset){
	
		//this.Easting = easting;
		//this.Northing = northing;
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
	
	public double[] getMyResult(){
		return myData;
	}
	
	//get Array Coordinates for drawing
	
	public double[] getArrayCoords(){
		double[] arrayCoords = new double[2];
		arrayCoords[0] = (getMyx(getMyResult()[2]))/headerData[0];
		arrayCoords[1] = (getMyy(getMyResult()[3]))/headerData[1];
		return arrayCoords;
		
	}
	
	public double[] getMyPositionDraw(){
		double[] myPos = new double[2];
		myPos [0] = (Easting)/headerData[0];
		myPos [1] = (Northing)/headerData[1];
		return myPos;
	}
	
	//convert tuple to double[]
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
	
	//convert easting to array coordinates
	private static double getMyx(double Easting){
		double i = ((Easting - headerData[2])) / headerData[4];
		return i;
	}
	
	//convert Northing to Array Coordinates
	private static double getMyy(double Northing){
		double i = (headerData[0] - ((Northing - headerData[3])) / headerData[4]);
		return i;
	}
	
	
	/* -- DEEP TRIG MAGIC STARTS HERE --RM -- */
	// All angles, call makeAngle before you call these functions
	
	// this is a helper class to get around the fact that we can't return
	// tuples in java
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
	
	//convert bearing into direction
	private static double makeAngle(double degrees) {
		double realDegrees = 360 - 
			(degrees - 90); // to turn our bearing into a degree from y=0
		return Math.toRadians(realDegrees);
	}
	
	private static xyTuple getCellAt(double theta, double d, double cellsize) {
			double x = Math.cos(theta) * d;
			double y = Math.sin(theta) * d;
			int xcell = (int) Math.floor(x / cellsize);
			int ycell = (int) Math.floor(y / cellsize);
			return new xyTuple(x, y, xcell, ycell);
	}
	
	
	
	//extract floorheight from data array
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
	
	//calculate height I can see from data in correct format
	
	private static dhTuple heightICanSee(double theta, double elevation, double[][] universe, 
								  double cellsize, int myx, int myy, double myHeight) {
		double d = cellsize * 4 + 0.1; // enter number of cells to ignore here (if any).
		                     // This is so that we ignore the cell we are 'in'.
		double dincr = cellsize;
		xyTuple xy = null;
		
		
			
		try { 
			while (d < (universe[0].length * cellsize)/2) {
				xy = getCellAt(theta, d, cellsize);
				
				double h = getHeightAt(elevation, d, myHeight);

				// The strange -s are because we have to flip from 'geometry' to 'array index'
				
				
				if (h < universe[myy-xy.ycell - 1][myx + xy.xcell]){
					//int E = (int) ((int) ((myx + xy.xcell) * headerData[4]) + headerData[2]);
					//int N = (int) ((int) ((int) ((headerData[0] - myy+xy.ycell - 1)  * headerData[4])) + headerData[3]);
					//System.out.println("E = " + E + " N = " + N);
					distanceToTarget = d;
					return new dhTuple(d, (universe[myy-xy.ycell - 1][myx + xy.xcell]),myy-xy.ycell - 1, myx + xy.xcell);
				}
				
				
				d += dincr;
				
			}
		} catch (ArrayIndexOutOfBoundsException e) {
			//System.out.println("** The world is flat and we fell off it.");
			return null;
		}
		//System.out.println("** Can't see anything at this distance.");
		return null;
	}
	
	public double getMyHeight(){
		return myHeight;
	}
	
	public double[] getMyArrayCoords(){
		double[] myArrayCoords = new double[2];
		
		myArrayCoords[0] = getMyx(getMyResult()[2]);
		myArrayCoords[1] = getMyy(getMyResult()[3]);
		
		return myArrayCoords;
		
	}
	public double getDistanceToTarget(){
		return distanceToTarget;
		
	}
	
	
	
}
