import React from 'react';
import { Routes, Route } from 'react-router-dom';
import DoctorHome from './DoctorHome';
import DoctorPatients from './DoctorPatients';
import DoctorExams from './DoctorExams';
import DoctorResults from './DoctorResults';

const DoctorDashboard = () => {
  return (
    <Routes>
      <Route index element={<DoctorHome />} />
      <Route path="patients" element={<DoctorPatients />} />
      <Route path="exams" element={<DoctorExams />} />
      <Route path="results" element={<DoctorResults />} />
    </Routes>
  );
};

export default DoctorDashboard;