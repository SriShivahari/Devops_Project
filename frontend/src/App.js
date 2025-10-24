import axios from "axios";
import { useState } from "react";
import React from "react";
import PredictionForm from "./components/PredictionForm";

function App() {
  const [input, setInput] = useState("");
  const [result, setResult] = useState("");

  const handleSubmit = async () => {
    const res = await axios.post("http://localhost:5000/predict", { data: input });
    setResult(res.data.result);
  };

  return (
    <div className="App">
      <h1>ML Prediction Dashboard</h1>
      <input value={input} onChange={(e) => setInput(e.target.value)} />
      <button onClick={handleSubmit}>Submit</button>
      <p>Result: {result}</p>
    </div>
  );
}


function App() {
  return (
    <div className="min-h-screen bg-gray-50 flex flex-col items-center justify-center">
      <h1 className="text-3xl font-bold mb-6">Text Classification App</h1>
      <PredictionForm />
    </div>
  );
}

export default App;


