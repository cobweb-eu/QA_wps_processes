package pillar.authoritativedata;

import java.util.List;
import java.util.Map;

import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
//Process to compare the entry of one field to a list of authoritative data
//could be used to compare plant names to a list of known species
public class OneColumnLookup extends AbstractAlgorithm{

	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Class<?> getInputDataType(String id) {
		if (id.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		if (id.equalsIgnoreCase("inputAuthoritativeData")){
			return GenericFileDataBinding.class;
		}
		
		return null;
	}

	@Override
	public Class<?> getOutputDataType(String id) {
		// TODO Auto-generated method stub
		return null;
	}

}
