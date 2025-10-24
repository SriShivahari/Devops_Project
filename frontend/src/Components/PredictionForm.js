import React, { useState } from "react";
import axios from "axios";

function PredictionForm() {
  const [text, setText] = useState("");
  const [prediction, setPrediction] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await axios.post("http://localhost:5000/predict", { text });
      setPrediction(res.data.label);
    } catch (err) {
      console.error(err);
      setPrediction("Error: Could not get prediction");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white shadow-md p-6 rounded-xl w-96">
      <form onSubmit={handleSubmit}>
        <textarea
          className="w-full border p-2 rounded-md mb-3"
          rows="4"
          placeholder="Enter text to classify"
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
        <button
          type="submit"
          className="bg-blue-600 text-white px-4 py-2 rounded-md w-full"
          disabled={loading}
        >
          {loading ? "Predicting..." : "Submit"}
        </button>
      </form>
      {prediction && (
        <div className="mt-4 p-3 bg-gray-100 rounded-md text-center">
          <strong>Prediction:</strong> {prediction}
        </div>
      )}
    </div>
  );
}

export default PredictionForm;
