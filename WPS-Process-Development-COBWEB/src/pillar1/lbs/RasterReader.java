package pillar1.lbs;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class RasterReader {
	
	/**
	 * @author Sam Meek
	 * Process to assess parse a raster in the ESRI grid format
	 * Output is a 2 dimensional array 
	 */
	
	String fileName;
	static double [] headerData = new double[6];
	double [][]ASCIIData;
	
	
	public RasterReader(String fileName){
		
		this.fileName = fileName;
		
		headerData = getRasterHeader(fileName);
		ASCIIData = new double[(int)headerData[0]][(int)headerData[1]];
		ASCIIData = inputASCIIData(fileName);
	}
	
	//eMod and nMod are the numbers the raster start and finish should be modified by
	//i.e. 5m resolution raster but taken starting with an E of 1 would be eMod 1;
	
	//read in header data of study area to calculate the viewshed tile required
	private static double[] getRasterHeader(String file){
	
	BufferedReader br = null;
	
	double[] headerData = new double[6];
	//read in header
	try {
		br = new BufferedReader(new FileReader(file));
		
		String line = null;
		double var;
							
		for(int i = 0; i < 6; i++){
						
			line = br.readLine();
			char[] buffer = new char[line.length()];	
		 	line.getChars(14,line.length(), buffer, 0);
			String s = String.valueOf(buffer);
			var = Double.parseDouble(s);
			headerData[i] = var;
						
		}
		br.close();
		
	
	}
	catch(Exception e){
		System.out.println("RR Exception = " + e);
	}
	
	return headerData;
	}
	// read in the raster
	private static double[][] inputASCIIData(String rasterPath){
		BufferedReader br = null;
		
		headerData = new double[6];
		
		double[][] ASCIIData = null;
	
		
		//read in headers
		try {
			//read in DSM
			br = new BufferedReader(new FileReader(rasterPath));
			
			String DSMline = null;
			
			double var;
								
			//get header data from DSM
			for(int i = 0; i < 6; i++){
							
				DSMline = br.readLine();
				
				char[] buffer = new char[DSMline.length()];	
				DSMline.getChars(14,DSMline.length(), buffer, 0);
				String s = String.valueOf(buffer);
				var = Double.parseDouble(s);
				headerData[i] = var;
							
				//System.out.println("H = " + var);
				
			} 
			
			//read in DSM values
		
			ASCIIData = new double[(int) headerData[0]][(int) headerData[1]];
		
			for(int i = 0;i < headerData[0];i++){
				DSMline = br.readLine();
				String [] temp = new String[(int) headerData[1]];
				temp = DSMline.split(" ");
			
				
				for(int j = 0;j < headerData[1];j++){
					//read in LiDAR
					ASCIIData[i][j] = Double.parseDouble(temp[j]);
					
				 	}
									
				}
			
			br.close();
		
			
			System.out.println("Raster read in!");
			
							
		}
			
			catch( IOException e ) {
				e.printStackTrace();
			}
			catch(NullPointerException e){
				System.out.println("NullPointerException" + e);
			}
			
			
			return ASCIIData;             
		}
	
	public double[][] getASCIIData(){
		return ASCIIData;
	}
	
	public double[] getASCIIHeader(){
		return headerData;
	}
	
	
}
