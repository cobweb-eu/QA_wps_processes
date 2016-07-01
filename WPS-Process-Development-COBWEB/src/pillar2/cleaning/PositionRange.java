package pillar2.cleaning;

import java.util.List;
import java.util.Map;

import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;

//position range is within a radius of a point

public class PositionRange extends AbstractAlgorithm{
	
	/**
	 * @author Sam Meek
	 * Process unfinished
	 * 
	 */
	
	private final String inputObservations = "inputObservations";
	private final String inputDistance = "inputDistance";
	

	@Override
	public Class<?> getInputDataType(String identifier) {
		if (identifier.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		if(identifier.equalsIgnoreCase("inputDistance")){
			return LiteralDoubleBinding.class;
		}
		return null;
	}

	@Override
	public Class<?> getOutputDataType(String arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Map<String, IData> run(Map<String, List<IData>> arg0)
			throws ExceptionReport {
		// TODO Auto-generated method stub
		return null;
	}
	
	@Override
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}

}
