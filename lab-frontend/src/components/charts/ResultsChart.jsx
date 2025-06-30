import React from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { format } from 'date-fns';

const ResultsChart = ({ data, examType, title }) => {
  if (!data || data.length === 0) {
    return (
      <div className="card text-center py-8">
        <p className="text-gray-500">Não há dados suficientes para exibir o gráfico</p>
      </div>
    );
  }

  // Preparar dados para o gráfico
  const chartData = data.map(item => ({
    date: format(new Date(item.performed_at || item.date), 'dd/MM/yy'),
    value: parseFloat(item.value),
    fullDate: new Date(item.performed_at || item.date),
    status: item.status || 'normal'
  })).sort((a, b) => a.fullDate - b.fullDate);

  // Configuração de cores baseada no status
  const getLineColor = () => {
    const hasAbnormal = chartData.some(item => item.status !== 'normal');
    return hasAbnormal ? '#ef4444' : '#10b981'; // Vermelho se houver anormais, verde se normal
  };

  // Faixas de referência (se disponível)
  const referenceRange = examType?.reference_range;
  let referenceBands = [];
  
  if (referenceRange) {
    const match = referenceRange.match(/(\d+\.?\d*)-(\d+\.?\d*)/);
    if (match) {
      const min = parseFloat(match[1]);
      const max = parseFloat(match[2]);
      referenceBands = [
        { y1: min, y2: max, fill: '#10b981', fillOpacity: 0.1 }
      ];
    }
  }

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <div className="bg-white p-3 border border-gray-200 rounded-lg shadow-lg">
          <p className="font-medium">{`Data: ${label}`}</p>
          <p className="text-blue-600">
            {`Valor: ${payload[0].value} ${examType?.unit || ''}`}
          </p>
          <p className={`text-sm ${
            data.status === 'high' ? 'text-red-600' :
            data.status === 'low' ? 'text-orange-600' :
            'text-green-600'
          }`}>
            Status: {
              data.status === 'high' ? 'Alto' :
              data.status === 'low' ? 'Baixo' :
              'Normal'
            }
          </p>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="card">
      <div className="mb-4">
        <h3 className="text-lg font-medium text-gray-900">
          {title || `Tendência - ${examType?.name}`}
        </h3>
        {examType?.reference_range && (
          <p className="text-sm text-gray-500">
            Faixa de referência: {examType.reference_range}
          </p>
        )}
      </div>

      <div className="h-80">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis 
              dataKey="date" 
              stroke="#6b7280"
              fontSize={12}
            />
            <YAxis 
              stroke="#6b7280"
              fontSize={12}
              label={{ 
                value: examType?.unit || 'Valor', 
                angle: -90, 
                position: 'insideLeft',
                style: { textAnchor: 'middle' }
              }}
            />
            <Tooltip content={<CustomTooltip />} />
            <Legend />
            
            {/* Faixas de referência */}
            {referenceBands.map((band, index) => (
              <defs key={index}>
                <pattern id={`referenceBand${index}`} patternUnits="userSpaceOnUse" width="4" height="4">
                  <rect width="4" height="4" fill={band.fill} fillOpacity={band.fillOpacity} />
                </pattern>
              </defs>
            ))}
            
            <Line 
              type="monotone" 
              dataKey="value" 
              stroke={getLineColor()}
              strokeWidth={2}
              dot={{ fill: getLineColor(), strokeWidth: 2, r: 4 }}
              activeDot={{ r: 6, stroke: getLineColor(), strokeWidth: 2 }}
              name={`${examType?.name || 'Resultado'} (${examType?.unit || ''})`}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Legenda de status */}
      <div className="mt-4 flex justify-center space-x-6 text-sm">
        <div className="flex items-center">
          <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
          <span>Normal</span>
        </div>
        <div className="flex items-center">
          <div className="w-3 h-3 bg-orange-500 rounded-full mr-2"></div>
          <span>Baixo</span>
        </div>
        <div className="flex items-center">
          <div className="w-3 h-3 bg-red-500 rounded-full mr-2"></div>
          <span>Alto</span>
        </div>
      </div>
    </div>
  );
};

export default ResultsChart;