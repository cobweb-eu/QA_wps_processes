package example.test;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.literal.LiteralIntBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;

public class ReturnNumber extends AbstractAlgorithm{
Logger LOG = Logger.getLogger(ReturnNumber.class);
	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		
		List <IData> inList = inputData.get("giveNumber");
		
		int number = ((LiteralIntBinding)inList.get(0)).getPayload();
		
		LOG.warn("giveNumber " + number );
		
		int outNumber = number + 1;
		
		LOG.warn("outNumber " + outNumber);
		
		HashMap<String, IData> result = new HashMap<String, IData>();
		
		result.put("getNumber", new LiteralStringBinding (""+outNumber));
		
		
		return result;
	}

	@Override
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Class<?> getInputDataType(String id) {
		if(id.equalsIgnoreCase("giveNumber")){
			return LiteralIntBinding.class;
		}
		return null;
	}

	@Override
	public Class<?> getOutputDataType(String id) {
		if(id.equalsIgnoreCase("getNumber")){
			return LiteralStringBinding.class;
		}
		return null;
	}

}
