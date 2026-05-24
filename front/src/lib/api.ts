import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3002/api';

export const api = {
  get: (table: string) => axios.get(`${API_URL}/game-data/${table}`).then(res => res.data),
  getOne: (table: string, id: string) => axios.get(`${API_URL}/game-data/${table}/${id}`).then(res => res.data),
  create: (table: string, data: any) => axios.post(`${API_URL}/game-data/${table}`, data).then(res => res.data),
  update: (table: string, id: string, data: any) => axios.patch(`${API_URL}/game-data/${table}/${id}`, data).then(res => res.data),
  delete: (table: string, id: string) => axios.delete(`${API_URL}/game-data/${table}/${id}`).then(res => res.data),
  getRelations: (table: string, id: string, relationTable: string, joinField: string) => 
    axios.get(`${API_URL}/game-data/${table}/${id}/relations`, { params: { relationTable, joinField } }).then(res => res.data),
  addRelation: (table: string, payload: any) => axios.post(`${API_URL}/game-data/relations/${table}`, payload).then(res => res.data),
  removeRelation: (table: string, query: any) => axios.delete(`${API_URL}/game-data/relations/${table}`, { params: query }).then(res => res.data),
};
